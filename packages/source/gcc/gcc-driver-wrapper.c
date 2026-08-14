#include <errno.h>
#include <limits.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>

#ifndef REAL_DRIVER
#error "REAL_DRIVER must name the wrapped GCC driver"
#endif

static void fail(const char *message) {
  perror(message);
  exit(127);
}

int main(int argc, char **argv) {
  char prefix[PATH_MAX];
  ssize_t length = readlink("/proc/self/exe", prefix, sizeof(prefix) - 1);
  if (length < 0 || (size_t)length >= sizeof(prefix) - 1) {
    fail("readlink /proc/self/exe");
  }
  prefix[length] = '\0';

  char *separator = strrchr(prefix, '/');
  if (separator == NULL) {
    errno = EINVAL;
    fail("locate GCC bin directory");
  }
  *separator = '\0';
  separator = strrchr(prefix, '/');
  if (separator == NULL) {
    errno = EINVAL;
    fail("locate GCC prefix");
  }
  *separator = '\0';

  char real_driver[PATH_MAX];
  char sysroot_arg[PATH_MAX + 16];
  char linker_arg[PATH_MAX + 32];
  if (snprintf(real_driver, sizeof(real_driver), "%s/bin/%s", prefix,
               REAL_DRIVER) >= (int)sizeof(real_driver) ||
      snprintf(sysroot_arg, sizeof(sysroot_arg),
               "--sysroot=%s/lib/bootstrap-sysroot", prefix) >=
          (int)sizeof(sysroot_arg) ||
      snprintf(linker_arg, sizeof(linker_arg),
               "-Wl,--dynamic-linker=%s/lib/ld-linux-x86-64.so.2", prefix) >=
          (int)sizeof(linker_arg)) {
    errno = ENAMETOOLONG;
    fail("construct GCC wrapper arguments");
  }

  char **wrapped_argv = calloc((size_t)argc + 3, sizeof(*wrapped_argv));
  if (wrapped_argv == NULL) {
    fail("allocate GCC wrapper arguments");
  }
  wrapped_argv[0] = real_driver;
  wrapped_argv[1] = sysroot_arg;
  wrapped_argv[2] = linker_arg;
  for (int i = 1; i < argc; ++i) {
    wrapped_argv[i + 2] = argv[i];
  }

  execv(real_driver, wrapped_argv);
  fail(real_driver);
  return 127;
}
