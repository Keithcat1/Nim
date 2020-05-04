# Posix detect program
# (c) 2010 Andreas Rumpf

# This program generates:
# * A c program that prints a nim file containing constant variables holding the
#   value of many C #define's, on the platform it's currently running at
# * A nim file that contains the same contants, but as nim var:s that fetch the
#   value of the constant using importc/header during the C compile phase.
#
# The first file allows nim to know the value of the constant at nim
# compile time, but since the values differ across platform, isn't as portable.
# The second one is more portable, and less semantically correct. It only works
# when there's a backing C compiler available as well, preventing standalone
# compilation.
import os, strutils

const
  cc = "gcc -o $# $#.c"
  cpp = "gcc -E -o $#.i $#.c"

  cfile = """
/* Generated by detect.nim */
#define _GNU_SOURCE
#define _POSIX_C_SOURCE 200809L

#include <stdlib.h>
#include <stdio.h>
$1

int main() {
  FILE* f;
  f = fopen("$3_$4_consts.nim", "w+");
  fputs("# Generated by detect.nim\n\n", f);
  $2
  fclose(f);
}
"""
  ifile = """
/* Generated by detect.nim */

$1
"""
  nimfile = """
# Generated by detect.nim
$1
"""

var
  cur = ""
  found = false
  hd = ""
  tl = ""
  other = ""

proc myExec(cmd: string): bool =
  echo "CMD ", cmd
  return execShellCmd(cmd) == 0

proc header(s: string) =
  cur = s
  const testh = "testh"
  var f: File
  if open(f, addFileExt(testh, "c"), fmWrite):
    f.write("#include $1\n" % s)
    f.write("int main() { return 0; }\n")
    close(f)
    found = myExec(cc % [testh.addFileExt(ExeExt), testh])
    removeFile(addFileExt(testh, "c"))

  addf(other, "\n# $1\n", cur)

  if found:
    addf(hd, "#include $1\n", cur)
    addf(tl, "  fprintf(f, \"\\n# $1\\n\");\n", cur)
    echo("Found: ", s)
  else:
    echo("Not found: ", s)

proc main =
  const gen = "genconsts"
  const pre = "pre"
  var f: File
  if open(f, addFileExt(gen, "c"), fmWrite):
    f.write(cfile % [hd, tl, system.hostOS, system.hostCPU])
    close(f)
  if open(f, addFileExt(pre, "c"), fmWrite):
    f.write(cfile % [hd, tl, system.hostOS, system.hostCPU])
    close(f)
  if open(f, "other_consts.nim", fmWrite):
    f.write(nimfile % [other])
    close(f)
  if not myExec(cc % [gen.addFileExt(ExeExt), gen]): quit(1)
  if not myExec(cpp % [pre.addFileExt(ExeExt), pre]): quit(1)
  when defined(windows):
    if not myExec(gen.addFileExt(ExeExt)): quit(1)
  else:
    if not myExec("./" & gen): quit(1)
  #removeFile(addFileExt(gen, "c"))
  echo("Success")

proc v(name: string, typ = "cint", no_other = false) =
  var n = if name[0] == '_': substr(name, 1) else: name
  var t = $typ

  if not no_other:
    addf(other,
      "var $1* {.importc: \"$2\", header: \"$3\".}: $4\n", n, name, cur, t)

  if not found: return

  case typ
  of "pointer":
    addf(tl,
      "#ifdef $3\n  fprintf(f, \"const $1* = cast[$2](%p)\\n\", $3);\n#endif\n",
      n, t, name)
  of "cstring":
    addf(tl,
      "#ifdef $3\n  fprintf(f, \"const $1* = $2(\\\"%s\\\")\\n\", $3);\n#endif\n",
      n, t, name)
  of "clong":
    addf(tl,
      "#ifdef $3\n  fprintf(f, \"const $1* = $2(%ld)\\n\", $3);\n#endif\n",
      n, t, name)
  of "cint", "cshort", "TSa_Family":
    addf(tl,
      "#ifdef $3\n  fprintf(f, \"const $1* = $2(%d)\\n\", $3);\n#endif\n",
      n, t, name)
  of "InAddrScalar":
    addf(tl,
      "#ifdef $3\n  fprintf(f, \"const $1* = $2(%u)\\n\", $3);\n#endif\n",
      n, t, name)
  else:
    addf(tl,
      "#ifdef $3\n  fprintf(f, \"const $1* = cast[$2](%d)\\n\", $3);\n#endif\n",
      n, t, name)


header("<aio.h>")
v("AIO_ALLDONE")
v("AIO_CANCELED")
v("AIO_NOTCANCELED")
v("LIO_NOP")
v("LIO_NOWAIT")
v("LIO_READ")
v("LIO_WAIT")
v("LIO_WRITE")

header("<dlfcn.h>")
v("RTLD_LAZY")
v("RTLD_NOW")
v("RTLD_GLOBAL")
v("RTLD_LOCAL")

header("<errno.h>")
v("E2BIG")
v("EACCES")
v("EADDRINUSE")
v("EADDRNOTAVAIL")
v("EAFNOSUPPORT")
v("EAGAIN")
v("EALREADY")
v("EBADF")
v("EBADMSG")
v("EBUSY")
v("ECANCELED")
v("ECHILD")
v("ECONNABORTED")
v("ECONNREFUSED")
v("ECONNRESET")
v("EDEADLK")
v("EDESTADDRREQ")
v("EDOM")
v("EDQUOT")
v("EEXIST")
v("EFAULT")
v("EFBIG")
v("EHOSTUNREACH")
v("EIDRM")
v("EILSEQ")
v("EINPROGRESS")
v("EINTR")
v("EINVAL")
v("EIO")
v("EISCONN")
v("EISDIR")
v("ELOOP")
v("EMFILE")
v("EMLINK")
v("EMSGSIZE")
v("EMULTIHOP")
v("ENAMETOOLONG")
v("ENETDOWN")
v("ENETRESET")
v("ENETUNREACH")
v("ENFILE")
v("ENOBUFS")
v("ENODATA")
v("ENODEV")
v("ENOENT")
v("ENOEXEC")
v("ENOLCK")
v("ENOLINK")
v("ENOMEM")
v("ENOMSG")
v("ENOPROTOOPT")
v("ENOSPC")
v("ENOSR")
v("ENOSTR")
v("ENOSYS")
v("ENOTCONN")
v("ENOTDIR")
v("ENOTEMPTY")
v("ENOTSOCK")
v("ENOTSUP")
v("ENOTTY")
v("ENXIO")
v("EOPNOTSUPP")
v("EOVERFLOW")
v("EPERM")
v("EPIPE")
v("EPROTO")
v("EPROTONOSUPPORT")
v("EPROTOTYPE")
v("ERANGE")
v("EROFS")
v("ESPIPE")
v("ESRCH")
v("ESTALE")
v("ETIME")
v("ETIMEDOUT")
v("ETXTBSY")
v("EWOULDBLOCK")
v("EXDEV")

header("<fcntl.h>")
v("F_DUPFD")
v("F_DUPFD_CLOEXEC")
v("F_GETFD")
v("F_SETFD")
v("F_GETFL")
v("F_SETFL")
v("F_GETLK")
v("F_SETLK")
v("F_SETLKW")
v("F_GETOWN")
v("F_SETOWN")
v("FD_CLOEXEC")
v("F_RDLCK")
v("F_UNLCK")
v("F_WRLCK")
v("O_CREAT")
v("O_EXCL")
v("O_NOCTTY")
v("O_TRUNC")
v("O_APPEND")
v("O_DSYNC")
v("O_NONBLOCK")
v("O_RSYNC")
v("O_SYNC")
v("O_ACCMODE")
v("O_RDONLY")
v("O_RDWR")
v("O_WRONLY")
v("O_CLOEXEC")
v("O_DIRECT")
v("O_PATH")
v("O_NOATIME")
v("O_TMPFILE")
v("POSIX_FADV_NORMAL")
v("POSIX_FADV_SEQUENTIAL")
v("POSIX_FADV_RANDOM")
v("POSIX_FADV_WILLNEED")
v("POSIX_FADV_DONTNEED")
v("POSIX_FADV_NOREUSE")

header("<fenv.h>")
v("FE_DIVBYZERO")
v("FE_INEXACT")
v("FE_INVALID")
v("FE_OVERFLOW")
v("FE_UNDERFLOW")
v("FE_ALL_EXCEPT")
v("FE_DOWNWARD")
v("FE_TONEAREST")
v("FE_TOWARDZERO")
v("FE_UPWARD")
v("FE_DFL_ENV")

header("<fmtmsg.h>")
v("MM_HARD")
v("MM_SOFT")
v("MM_FIRM")
v("MM_APPL")
v("MM_UTIL")
v("MM_OPSYS")
v("MM_RECOVER")
v("MM_NRECOV")
v("MM_HALT")
v("MM_ERROR")
v("MM_WARNING")
v("MM_INFO")
v("MM_NOSEV")
v("MM_PRINT")
v("MM_CONSOLE")
v("MM_OK")
v("MM_NOTOK")
v("MM_NOMSG")
v("MM_NOCON")

header("<fnmatch.h>")
v("FNM_NOMATCH")
v("FNM_PATHNAME")
v("FNM_PERIOD")
v("FNM_NOESCAPE")
v("FNM_NOSYS")

header("<ftw.h>")
v("FTW_F")
v("FTW_D")
v("FTW_DNR")
v("FTW_DP")
v("FTW_NS")
v("FTW_SL")
v("FTW_SLN")
v("FTW_PHYS")
v("FTW_MOUNT")
v("FTW_DEPTH")
v("FTW_CHDIR")

header("<glob.h>")
v("GLOB_APPEND")
v("GLOB_DOOFFS")
v("GLOB_ERR")
v("GLOB_MARK")
v("GLOB_NOCHECK")
v("GLOB_NOESCAPE")
v("GLOB_NOSORT")
v("GLOB_ABORTED")
v("GLOB_NOMATCH")
v("GLOB_NOSPACE")
v("GLOB_NOSYS")

header("<langinfo.h>")
v("CODESET")
v("D_T_FMT")
v("D_FMT")
v("T_FMT")
v("T_FMT_AMPM")
v("AM_STR")
v("PM_STR")
v("DAY_1")
v("DAY_2")
v("DAY_3")
v("DAY_4")
v("DAY_5")
v("DAY_6")
v("DAY_7")
v("ABDAY_1")
v("ABDAY_2")
v("ABDAY_3")
v("ABDAY_4")
v("ABDAY_5")
v("ABDAY_6")
v("ABDAY_7")
v("MON_1")
v("MON_2")
v("MON_3")
v("MON_4")
v("MON_5")
v("MON_6")
v("MON_7")
v("MON_8")
v("MON_9")
v("MON_10")
v("MON_11")
v("MON_12")
v("ABMON_1")
v("ABMON_2")
v("ABMON_3")
v("ABMON_4")
v("ABMON_5")
v("ABMON_6")
v("ABMON_7")
v("ABMON_8")
v("ABMON_9")
v("ABMON_10")
v("ABMON_11")
v("ABMON_12")
v("ERA")
v("ERA_D_FMT")
v("ERA_D_T_FMT")
v("ERA_T_FMT")
v("ALT_DIGITS")
v("RADIXCHAR")
v("THOUSEP")
v("YESEXPR")
v("NOEXPR")
v("CRNCYSTR")

header("<locale.h>")
v("LC_ALL")
v("LC_COLLATE")
v("LC_CTYPE")
v("LC_MESSAGES")
v("LC_MONETARY")
v("LC_NUMERIC")
v("LC_TIME")

header("<netdb.h>")
v("IPPORT_RESERVED")
v("HOST_NOT_FOUND")
v("NO_DATA")
v("NO_RECOVERY")
v("TRY_AGAIN")
v("AI_PASSIVE")
v("AI_CANONNAME")
v("AI_NUMERICHOST")
v("AI_NUMERICSERV")
v("AI_V4MAPPED")
v("AI_ALL")
v("AI_ADDRCONFIG")
v("NI_NOFQDN")
v("NI_NUMERICHOST")
v("NI_NAMEREQD")
v("NI_NUMERICSERV")
v("NI_NUMERICSCOPE")
v("NI_DGRAM")
v("EAI_AGAIN")
v("EAI_BADFLAGS")
v("EAI_FAIL")
v("EAI_FAMILY")
v("EAI_MEMORY")
v("EAI_NONAME")
v("EAI_SERVICE")
v("EAI_SOCKTYPE")
v("EAI_SYSTEM")
v("EAI_OVERFLOW")

header("<net/if.h>")
v("IF_NAMESIZE")

header("<netinet/in.h>")
v("IPPROTO_IP")
v("IPPROTO_IPV6")
v("IPPROTO_ICMP")
v("IPPROTO_ICMPV6")
v("IPPROTO_RAW")
v("IPPROTO_TCP")
v("IPPROTO_UDP")
v("INADDR_ANY", "InAddrScalar")
v("INADDR_LOOPBACK", "InAddrScalar")
v("INADDR_BROADCAST", "InAddrScalar")
v("INET_ADDRSTRLEN")
v("INET6_ADDRSTRLEN")
v("IPV6_JOIN_GROUP")
v("IPV6_LEAVE_GROUP")
v("IPV6_MULTICAST_HOPS")
v("IPV6_MULTICAST_IF")
v("IPV6_MULTICAST_LOOP")
v("IPV6_UNICAST_HOPS")
v("IPV6_V6ONLY")

header("<netinet/tcp.h>")
v("TCP_NODELAY")

header("<nl_types.h>")
v("NL_SETD")
v("NL_CAT_LOCALE")

header("<poll.h>")
v("POLLIN", "cshort")
v("POLLRDNORM", "cshort")
v("POLLRDBAND", "cshort")
v("POLLPRI", "cshort")
v("POLLOUT", "cshort")
v("POLLWRNORM", "cshort")
v("POLLWRBAND", "cshort")
v("POLLERR", "cshort")
v("POLLHUP", "cshort")
v("POLLNVAL", "cshort")

header("<pthread.h>")
v("PTHREAD_BARRIER_SERIAL_THREAD")
v("PTHREAD_CANCEL_ASYNCHRONOUS")
v("PTHREAD_CANCEL_ENABLE")
v("PTHREAD_CANCEL_DEFERRED")
v("PTHREAD_CANCEL_DISABLE")
  #v("PTHREAD_CANCELED")
  #v("PTHREAD_COND_INITIALIZER")
v("PTHREAD_CREATE_DETACHED")
v("PTHREAD_CREATE_JOINABLE")
v("PTHREAD_EXPLICIT_SCHED")
v("PTHREAD_INHERIT_SCHED")
v("PTHREAD_MUTEX_DEFAULT")
v("PTHREAD_MUTEX_ERRORCHECK")
  #v("PTHREAD_MUTEX_INITIALIZER")
v("PTHREAD_MUTEX_NORMAL")
v("PTHREAD_MUTEX_RECURSIVE")
  #v("PTHREAD_ONCE_INIT")
v("PTHREAD_PRIO_INHERIT")
v("PTHREAD_PRIO_NONE")
v("PTHREAD_PRIO_PROTECT")
v("PTHREAD_PROCESS_SHARED")
v("PTHREAD_PROCESS_PRIVATE")
v("PTHREAD_SCOPE_PROCESS")
v("PTHREAD_SCOPE_SYSTEM")

header("<sched.h>")
v("SCHED_FIFO")
v("SCHED_RR")
v("SCHED_SPORADIC")
v("SCHED_OTHER")

header("<semaphore.h>")
v("SEM_FAILED", "pointer")

header("<signal.h>")
v("SIGEV_NONE")
v("SIGEV_SIGNAL")
v("SIGEV_THREAD")
v("SIGABRT")
v("SIGALRM")
v("SIGBUS")
v("SIGCHLD")
v("SIGCONT")
v("SIGFPE")
v("SIGHUP")
v("SIGILL")
v("SIGINT")
v("SIGKILL")
v("SIGPIPE")
v("SIGQUIT")
v("SIGSEGV")
v("SIGSTOP")
v("SIGTERM")
v("SIGTSTP")
v("SIGTTIN")
v("SIGTTOU")
v("SIGUSR1")
v("SIGUSR2")
v("SIGPOLL")
v("SIGPROF")
v("SIGSYS")
v("SIGTRAP")
v("SIGURG")
v("SIGVTALRM")
v("SIGXCPU")
v("SIGXFSZ")
v("SA_NOCLDSTOP")
v("SIG_BLOCK")
v("SIG_UNBLOCK")
v("SIG_SETMASK")
v("SA_ONSTACK")
v("SA_RESETHAND")
v("SA_RESTART")
v("SA_SIGINFO")
v("SA_NOCLDWAIT")
v("SA_NODEFER")
v("SS_ONSTACK")
v("SS_DISABLE")
v("MINSIGSTKSZ")
v("SIGSTKSZ")

v("SIG_HOLD", "Sighandler")
v("SIG_DFL", "Sighandler")
v("SIG_ERR", "Sighandler")
v("SIG_IGN", "Sighandler")

header("<sys/ipc.h>")
v("IPC_CREAT")
v("IPC_EXCL")
v("IPC_NOWAIT")
v("IPC_PRIVATE")
v("IPC_RMID")
v("IPC_SET")
v("IPC_STAT")

header("<sys/mman.h>")
v("PROT_READ")
v("PROT_WRITE")
v("PROT_EXEC")
v("PROT_NONE")
v("MAP_ANONYMOUS")
v("MAP_FIXED_NOREPLACE")
v("MAP_NORESERVE")
v("MAP_SHARED")
v("MAP_PRIVATE")
v("MAP_FIXED")
v("MS_ASYNC")
v("MS_SYNC")
v("MS_INVALIDATE")
v("MCL_CURRENT")
v("MCL_FUTURE")
v("MAP_FAILED", "pointer")
v("POSIX_MADV_NORMAL")
v("POSIX_MADV_SEQUENTIAL")
v("POSIX_MADV_RANDOM")
v("POSIX_MADV_WILLNEED")
v("POSIX_MADV_DONTNEED")
v("POSIX_TYPED_MEM_ALLOCATE")
v("POSIX_TYPED_MEM_ALLOCATE_CONTIG")
v("POSIX_TYPED_MEM_MAP_ALLOCATABLE")
v("MAP_POPULATE", no_other = true)

header("<sys/resource.h>")
v("RLIMIT_NOFILE")

header("<sys/select.h>")
v("FD_SETSIZE")

header("<sys/socket.h>")
v("MSG_CTRUNC")
v("MSG_DONTROUTE")
v("MSG_EOR")
v("MSG_OOB")
v("SCM_RIGHTS")
v("SO_ACCEPTCONN")
v("SO_BROADCAST")
v("SO_DEBUG")
v("SO_DONTROUTE")
v("SO_ERROR")
v("SO_KEEPALIVE")
v("SO_LINGER")
v("SO_OOBINLINE")
v("SO_RCVBUF")
v("SO_RCVLOWAT")
v("SO_RCVTIMEO")
v("SO_REUSEADDR")
v("SO_SNDBUF")
v("SO_SNDLOWAT")
v("SO_SNDTIMEO")
v("SO_TYPE")
v("SOCK_DGRAM")
v("SOCK_RAW")
v("SOCK_SEQPACKET")
v("SOCK_STREAM")
v("SOCK_CLOEXEC", no_other = true)
v("SOL_SOCKET")
v("SOMAXCONN")
v("SO_REUSEPORT", no_other = true)
v("MSG_NOSIGNAL", no_other = true)
v("MSG_PEEK")
v("MSG_TRUNC")
v("MSG_WAITALL")
v("AF_INET")
v("AF_INET6")
v("AF_UNIX")
v("AF_UNSPEC")
v("SHUT_RD")
v("SHUT_RDWR")
v("SHUT_WR")

header("<sys/stat.h>")
v("S_IFBLK")
v("S_IFCHR")
v("S_IFDIR")
v("S_IFIFO")
v("S_IFLNK")
v("S_IFMT")
v("S_IFREG")
v("S_IFSOCK")
v("S_IRGRP")
v("S_IROTH")
v("S_IRUSR")
v("S_IRWXG")
v("S_IRWXO")
v("S_IRWXU")
v("S_ISGID")
v("S_ISUID")
v("S_ISVTX")
v("S_IWGRP")
v("S_IWOTH")
v("S_IWUSR")
v("S_IXGRP")
v("S_IXOTH")
v("S_IXUSR")

header("<sys/statvfs.h>")
v("ST_RDONLY")
v("ST_NOSUID")

header("<sys/wait.h>")
v("WNOHANG")
v("WUNTRACED")
  #v("WEXITSTATUS")
  #v("WSTOPSIG")
  #v("WTERMSIG")
v("WEXITED")
v("WSTOPPED")
v("WCONTINUED")
v("WNOWAIT")
v("P_ALL")
v("P_PID")
v("P_PGID")

header("<spawn.h>")
v("POSIX_SPAWN_RESETIDS")
v("POSIX_SPAWN_SETPGROUP")
v("POSIX_SPAWN_SETSCHEDPARAM")
v("POSIX_SPAWN_SETSCHEDULER")
v("POSIX_SPAWN_SETSIGDEF")
v("POSIX_SPAWN_SETSIGMASK")
v("POSIX_SPAWN_USEVFORK", no_other = true)

header("<stdio.h>")
v("_IOFBF")
v("_IONBF")

header("<time.h>")
v("CLOCKS_PER_SEC", "clong")
v("CLOCK_PROCESS_CPUTIME_ID")
v("CLOCK_THREAD_CPUTIME_ID")
v("CLOCK_REALTIME")
v("TIMER_ABSTIME")
v("CLOCK_MONOTONIC")

header("<unistd.h>")
v("_POSIX_ASYNC_IO")
v("_POSIX_PRIO_IO")
v("_POSIX_SYNC_IO")
v("F_OK")
v("R_OK")
v("W_OK")
v("X_OK")
v("_CS_PATH")
v("_CS_POSIX_V6_ILP32_OFF32_CFLAGS")
v("_CS_POSIX_V6_ILP32_OFF32_LDFLAGS")
v("_CS_POSIX_V6_ILP32_OFF32_LIBS")
v("_CS_POSIX_V6_ILP32_OFFBIG_CFLAGS")
v("_CS_POSIX_V6_ILP32_OFFBIG_LDFLAGS")
v("_CS_POSIX_V6_ILP32_OFFBIG_LIBS")
v("_CS_POSIX_V6_LP64_OFF64_CFLAGS")
v("_CS_POSIX_V6_LP64_OFF64_LDFLAGS")
v("_CS_POSIX_V6_LP64_OFF64_LIBS")
v("_CS_POSIX_V6_LPBIG_OFFBIG_CFLAGS")
v("_CS_POSIX_V6_LPBIG_OFFBIG_LDFLAGS")
v("_CS_POSIX_V6_LPBIG_OFFBIG_LIBS")
v("_CS_POSIX_V6_WIDTH_RESTRICTED_ENVS")
v("F_LOCK")
v("F_TEST")
v("F_TLOCK")
v("F_ULOCK")
v("_PC_2_SYMLINKS")
v("_PC_ALLOC_SIZE_MIN")
v("_PC_ASYNC_IO")
v("_PC_CHOWN_RESTRICTED")
v("_PC_FILESIZEBITS")
v("_PC_LINK_MAX")
v("_PC_MAX_CANON")
v("_PC_MAX_INPUT")
v("_PC_NAME_MAX")
v("_PC_NO_TRUNC")
v("_PC_PATH_MAX")
v("_PC_PIPE_BUF")
v("_PC_PRIO_IO")
v("_PC_REC_INCR_XFER_SIZE")
v("_PC_REC_MIN_XFER_SIZE")
v("_PC_REC_XFER_ALIGN")
v("_PC_SYMLINK_MAX")
v("_PC_SYNC_IO")
v("_PC_VDISABLE")
v("_SC_2_C_BIND")
v("_SC_2_C_DEV")
v("_SC_2_CHAR_TERM")
v("_SC_2_FORT_DEV")
v("_SC_2_FORT_RUN")
v("_SC_2_LOCALEDEF")
v("_SC_2_PBS")
v("_SC_2_PBS_ACCOUNTING")
v("_SC_2_PBS_CHECKPOINT")
v("_SC_2_PBS_LOCATE")
v("_SC_2_PBS_MESSAGE")
v("_SC_2_PBS_TRACK")
v("_SC_2_SW_DEV")
v("_SC_2_UPE")
v("_SC_2_VERSION")
v("_SC_ADVISORY_INFO")
v("_SC_AIO_LISTIO_MAX")
v("_SC_AIO_MAX")
v("_SC_AIO_PRIO_DELTA_MAX")
v("_SC_ARG_MAX")
v("_SC_ASYNCHRONOUS_IO")
v("_SC_ATEXIT_MAX")
v("_SC_BARRIERS")
v("_SC_BC_BASE_MAX")
v("_SC_BC_DIM_MAX")
v("_SC_BC_SCALE_MAX")
v("_SC_BC_STRING_MAX")
v("_SC_CHILD_MAX")
v("_SC_CLK_TCK")
v("_SC_CLOCK_SELECTION")
v("_SC_COLL_WEIGHTS_MAX")
v("_SC_CPUTIME")
v("_SC_DELAYTIMER_MAX")
v("_SC_EXPR_NEST_MAX")
v("_SC_FSYNC")
v("_SC_GETGR_R_SIZE_MAX")
v("_SC_GETPW_R_SIZE_MAX")
v("_SC_HOST_NAME_MAX")
v("_SC_IOV_MAX")
v("_SC_IPV6")
v("_SC_JOB_CONTROL")
v("_SC_LINE_MAX")
v("_SC_LOGIN_NAME_MAX")
v("_SC_MAPPED_FILES")
v("_SC_MEMLOCK")
v("_SC_MEMLOCK_RANGE")
v("_SC_MEMORY_PROTECTION")
v("_SC_MESSAGE_PASSING")
v("_SC_MONOTONIC_CLOCK")
v("_SC_MQ_OPEN_MAX")
v("_SC_MQ_PRIO_MAX")
v("_SC_NGROUPS_MAX")
v("_SC_OPEN_MAX")
v("_SC_PAGESIZE") # Synonym for _SC_PAGE_SIZE
v("_SC_PRIORITIZED_IO")
v("_SC_PRIORITY_SCHEDULING")
v("_SC_RAW_SOCKETS")
v("_SC_RE_DUP_MAX")
v("_SC_READER_WRITER_LOCKS")
v("_SC_REALTIME_SIGNALS")
v("_SC_REGEXP")
v("_SC_RTSIG_MAX")
v("_SC_SAVED_IDS")
v("_SC_SEM_NSEMS_MAX")
v("_SC_SEM_VALUE_MAX")
v("_SC_SEMAPHORES")
v("_SC_SHARED_MEMORY_OBJECTS")
v("_SC_SHELL")
v("_SC_SIGQUEUE_MAX")
v("_SC_SPAWN")
v("_SC_SPIN_LOCKS")
v("_SC_SPORADIC_SERVER")
v("_SC_SS_REPL_MAX")
v("_SC_STREAM_MAX")
v("_SC_SYMLOOP_MAX")
v("_SC_SYNCHRONIZED_IO")
v("_SC_THREAD_ATTR_STACKADDR")
v("_SC_THREAD_ATTR_STACKSIZE")
v("_SC_THREAD_CPUTIME")
v("_SC_THREAD_DESTRUCTOR_ITERATIONS")
v("_SC_THREAD_KEYS_MAX")
v("_SC_THREAD_PRIO_INHERIT")
v("_SC_THREAD_PRIO_PROTECT")
v("_SC_THREAD_PRIORITY_SCHEDULING")
v("_SC_THREAD_PROCESS_SHARED")
v("_SC_THREAD_SAFE_FUNCTIONS")
v("_SC_THREAD_SPORADIC_SERVER")
v("_SC_THREAD_STACK_MIN")
v("_SC_THREAD_THREADS_MAX")
v("_SC_THREADS")
v("_SC_TIMEOUTS")
v("_SC_TIMER_MAX")
v("_SC_TIMERS")
v("_SC_TRACE")
v("_SC_TRACE_EVENT_FILTER")
v("_SC_TRACE_EVENT_NAME_MAX")
v("_SC_TRACE_INHERIT")
v("_SC_TRACE_LOG")
v("_SC_TRACE_NAME_MAX")
v("_SC_TRACE_SYS_MAX")
v("_SC_TRACE_USER_EVENT_MAX")
v("_SC_TTY_NAME_MAX")
v("_SC_TYPED_MEMORY_OBJECTS")
v("_SC_TZNAME_MAX")
v("_SC_V6_ILP32_OFF32")
v("_SC_V6_ILP32_OFFBIG")
v("_SC_V6_LP64_OFF64")
v("_SC_V6_LPBIG_OFFBIG")
v("_SC_VERSION")
v("_SC_XBS5_ILP32_OFF32")
v("_SC_XBS5_ILP32_OFFBIG")
v("_SC_XBS5_LP64_OFF64")
v("_SC_XBS5_LPBIG_OFFBIG")
v("_SC_XOPEN_CRYPT")
v("_SC_XOPEN_ENH_I18N")
v("_SC_XOPEN_LEGACY")
v("_SC_XOPEN_REALTIME")
v("_SC_XOPEN_REALTIME_THREADS")
v("_SC_XOPEN_SHM")
v("_SC_XOPEN_STREAMS")
v("_SC_XOPEN_UNIX")
v("_SC_XOPEN_VERSION")
v("_SC_NPROCESSORS_ONLN")
v("SEEK_SET")
v("SEEK_CUR")
v("SEEK_END")

main()
