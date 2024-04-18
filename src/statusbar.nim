import json, strutils, os, algorithm, hashes, sequtils
import libfuse, x11/xlib
import colors

type
  Options = object
    contents: cstring
    show_help: cint
  Block = object
    name: string
    content: string
    foreground: string
    background: string

var
  display: PDisplay
  options: Options
  contents: seq[Block]

template FUSE_OPT_END(): untyped =
  structFuseOpt(templ: nil, offset: 0, value: 0)

template option(t, p: untyped): untyped =
  structFuseOpt(templ: t, offset: offsetOf(options, p).culong, value: 1)

let option_spec = [
  option("--contents=%s", contents),
  option("-h", show_help),
  option("--help", show_help),
  FUSE_OPT_END
]

type
  Ground = enum fg, bg

proc tosgr(x: string, ground: Ground): string =
  result = case ground:
    of fg: "\x1b[38;2;"
    of bg: "\x1b[48;2;"
  result &= $x[0..1].parseHexInt & ";"
  result &= $x[2..3].parseHexInt & ";"
  result &= $x[4..5].parseHexInt & "m"

const
  reset = "\x1b[0m"
  clicksplit = "\x1f"

proc createStatus() =
  var status = ""
  for content in contents:
    status &= content.background.tosgr(fg) & "\uE0BE" & content.background.tosgr(bg) &
              content.foreground.tosgr(fg) & content.content.replace("\n", "") & reset &
              content.background.tosgr(fg) & "\uE0B8" & reset & clicksplit
  echo status
  echo XStoreName(display, RootWindow(display, DefaultScreen(display)), status.cstring)
  echo XSync(display, false.XBool)

proc blockExists(name: string): bool =
  for content in contents:
    if content.name == name: return true

proc hello_init(conn: ptr structFuseConnInfo, cfg: ptr structFuseConfig): pointer {.exportc, cdecl.} =
  cfg.kernel_cache = 1
  return nil

proc hello_getattr(path: cstring, stbuf: ptr struct_stat, fi: ptr struct_fuse_file_info): cint {.exportc, cdecl.} =
  stbuf.zeroMem(sizeof(struct_stat))
  echo "getattr"
  echo path
  let path = $path
  if path == "/":
    stbuf.stMode = (S_IFDIR or 0o755).compilerModeT
    stbuf.stNlink = 2
    return
  for content in contents:
    if path.startsWith "/" & content.name:
      if content.name.len + 1 == path.len:
        stbuf.stMode = (S_IFDIR or 0o755).compilerModeT
        stbuf.stNlink = 2
      elif path[2 + content.name.len..^1]  == "foreground":
        stbuf.stMode = (S_IFREG or 0o644).compilerModeT
        stbuf.stNlink = 1
        stbuf.stSize = content.foreground.len
      elif path[2 + content.name.len..^1]  == "background":
        stbuf.stMode = (S_IFREG or 0o644).compilerModeT
        stbuf.stNlink = 1
        stbuf.stSize = content.background.len
      elif path[2 + content.name.len..^1]  == "content":
        stbuf.stMode = (S_IFREG or 0o644).compilerModeT
        stbuf.stNlink = 1
        stbuf.stSize = content.content.len
      else: continue
      return
  return -ENOENT

proc hello_readdir(path: cstring, buf: pointer, filler: fuse_fill_dir_t,
       offset: off_t, fi: ptr struct_fuse_file_info,
       flags: enum_fuse_readdir_flags): cint {.exportc, cdecl.} =
  echo "readdir"
  echo path
  let path = $path
  if path == "/":
    discard filler(buf, ".".cstring, nil, 0, cast[enumfusefilldirflags](0))
    discard filler(buf, "..".cstring, nil, 0, cast[enumfusefilldirflags](0))
    for content in contents:
      discard filler(buf, content.name.cstring, nil, 0, cast[enumfusefilldirflags](0))
  else:
    block check:
      if path.startsWith("/"):
        for content in contents:
          if path[1..^1] == content.name:
            discard filler(buf, ".".cstring, nil, 0, cast[enumfusefilldirflags](0))
            discard filler(buf, "..".cstring, nil, 0, cast[enumfusefilldirflags](0))
            discard filler(buf, "content".cstring, nil, 0, cast[enumfusefilldirflags](0))
            discard filler(buf, "foreground".cstring, nil, 0, cast[enumfusefilldirflags](0))
            discard filler(buf, "background".cstring, nil, 0, cast[enumfusefilldirflags](0))
            break check
      return -ENOENT

proc hello_open(path: cstring, fi: ptr struct_fuse_file_info): cint {.exportc, cdecl.} =
  echo "open"
  echo path
  let split = ($path).split("/")
  if not (split.len == 3 and split[0].len == 0 and split[1].blockExists and split[2] in ["foreground", "background", "content"]):
    return -ENOENT

proc hello_read(path: cstring, buf: cstring, size: csizeT, offset: offT, fi: ptr struct_fuse_file_info): cint {.exportc, cdecl.} =
  echo "read"
  echo path
  let split = ($path).split("/")
  if not (split.len == 3 and split[0].len == 0):
    return -ENOENT
  block blockCheck:
    for content in contents:
      if split[1] == content.name:
        let
          fcontent =
            case split[2]:
            of "foreground": content.foreground
            of "background": content.background
            of "content": content.content
            else: return -ENOENT
          len = fcontent.len
        result = size.cint
        if offset < len:
          if offset.int + size.int > len:
            result = (len - offset).cint
          copyMem(buf, fcontent[offset].addr, result)
        else:
          result = 0
        break blockCheck
    return -ENOENT

proc hello_write(path: cstring, buf: cstring, size: csizeT, offset: offT, fi: ptr struct_fuse_file_info): cint {.exportc, cdecl.} =
  echo "write"
  echo path

  let append =
    if not fi.isNil:
      (fi.flags and O_APPEND) != 0
    else: true

  let split = ($path).split("/")
  if not (split.len == 3 and split[0].len == 0):
    return -ENOENT
  block blockCheck:
    for content in contents.mitems:
      if split[1] == content.name:
        var
          fcontent =
            case split[2]:
            of "foreground": content.foreground
            of "background": content.background
            of "content": content.content
            else: return -ENOENT
          strbuf = newString(size)
        copyMem(strbuf[0].addr, buf, size)
        if append:
          fcontent.setLen max(fcontent.len, offset.int + size.int)
          fcontent[offset.int..<offset.int+size.int] = strbuf[0..<size.int]
          result = size.cint
        else:
          fcontent = strbuf[0..<size.int]
          result = size.cint
        case split[2]:
        of "foreground":
          if fcontent.len != 6 or not fcontent.allCharsInSet HexDigits: return -ENOENT
          content.foreground = fcontent
        of "background":
          if fcontent.len != 6 or not fcontent.allCharsInSet HexDigits: return -ENOENT
          content.background = fcontent
        of "content": content.content = fcontent
        else: return -ENOENT
        break blockCheck
    return -ENOENT
  createStatus()

proc hello_create(path: cstring, mode: mode_t, fi: ptr struct_fuse_file_info): cint {.exportc, cdecl.} =
  echo "create"
  echo path

proc hello_mkdir(path: cstring, mode: modeT): cint {.exportc, cdecl.} =
  echo "mkdir"
  echo path
  let split = ($path).split("/")
  if split.len == 2 and split[0].len == 0 and not blockExists(split[1]):
    contents.add Block(name: split[1], content: "", foreground: "000000", background: nord[split[1].hash.uint mod nord.len.uint])
    contents = contents.sortedByIt it.name
    createStatus()
  else:
    return -ENOENT

proc hello_rmdir(path: cstring): cint {.exportc, cdecl.} =
  echo "rmdir"
  echo path
  let split = ($path).split("/")
  if split.len == 2 and split[0].len == 0 and blockExists(split[1]):
    contents = contents.filterIt(it.name != split[1])
    createStatus()
  else:
    return -ENOENT

proc hello_destroy(data: pointer) {.exportc, cdecl.} =
  echo "destroy"
  echo contents

let hello_oper = struct_fuse_operations(
    init:  hello_init,
    getattr: hello_getattr,
    readdir: hello_readdir,
    open: hello_open,
    read: hello_read,
    write: hello_write,
    create: hello_create,
    mkdir: hello_mkdir,
    rmdir: hello_rmdir,
    destroy: hello_destroy
  )

proc show_help(progname: cstring) =
  echo "usage: ", progname, " [options] <mountpoint>\n",
       "Mounts a filesystem backed by an in-memory JSON object. On unmount prints\n",
       "the JSON object as a string to stdout. All values are represented as text\n",
       "in files, and in JSON as base types if possible. Objects and arrays are\n",
       "stored as directories. All empty folders are empty objects, and folders\n",
       "with only files named with numbers in contiguous rising order starting\n",
       "from '0' are considered arrays.\n\n",
       "File-system specific options:\n",
       "    --contents=<s>         Contents of the mounted directory as a JSON\n",
       "                           object. Default: '{\"hello\": \"Hello World\"}'\n\n"

var
  cmdCount {.importc: "cmdCount".}: cint
  cmdLine {.importc: "cmdLine".}: cstringArray

let args = structFuseArgs(argc: cmdCount, argv: cast[ptr cstring](cmdLine))

# Set defaults -- we have to use strdup so that
# fuse_opt_parse can free the defaults if other
# values are specified
proc strdup(_: cstring): cstring {.importc, header: "string.h".}
options.contents = strdup("""{"hello": "Hello World!"}""")

# Parse options
if fuse_opt_parse(args.addr, options.addr, cast[ptr UncheckedArray[structFuseOpt]](option_spec.addr), nil) == -1:
  quit 1

# When --help is specified, first print our own file-system
# specific help text, then signal fuse_main to show
# additional help (by adding `--help` to the options again)
# without usage: line (by setting argv[0] to the empty
# string)
if options.show_help != 0:
  show_help(cmdLine[0])
  assert(fuse_opt_add_arg(args.addr, "--help") == 0)
  args.argv[0] = '\0'

#contents = parseJson($options.contents)
#echo contents

display = XOpenDisplay(nil)
if display == nil:
  echo "Unable to open X display"
  quit 1

discard XStoreName(display, RootWindow(display, DefaultScreen(display)), nil)
discard XSync(display, false.XBool)

let ret = fuse_main(args.argc, args.argv, hello_oper.addr, nil)
fuse_opt_free_args(args.addr)
quit ret
