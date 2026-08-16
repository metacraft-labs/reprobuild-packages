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

static int path_is_within(const char *path, const char *root) {
  size_t root_length = strlen(root);
  return strncmp(path, root, root_length) == 0 &&
         (path[root_length] == '\0' || path[root_length] == '/');
}

static int find_loader_in_library_path(const char *prefix, int allow_nix,
                                       char *loader, size_t loader_size) {
  const char *library_path = getenv("LIBRARY_PATH");
  if (library_path == NULL) {
    return 0;
  }

  const char *component = library_path;
  while (*component != '\0') {
    const char *end = strchr(component, ':');
    size_t length = end == NULL ? strlen(component) : (size_t)(end - component);
    if (length > 0 && length < PATH_MAX) {
      char directory[PATH_MAX];
      memcpy(directory, component, length);
      directory[length] = '\0';

      int is_nix = strncmp(directory, "/nix/store/", 11) == 0;
      if (!path_is_within(directory, prefix) && (allow_nix || !is_nix)) {
        char libc_path[PATH_MAX];
        int loader_length = snprintf(loader, loader_size,
                                     "%s/ld-linux-x86-64.so.2", directory);
        int libc_length = snprintf(libc_path, sizeof(libc_path),
                                   "%s/libc.so.6", directory);
        if (loader_length > 0 && (size_t)loader_length < loader_size &&
            libc_length > 0 && (size_t)libc_length < sizeof(libc_path) &&
            access(loader, X_OK) == 0 && access(libc_path, R_OK) == 0) {
          return 1;
        }
      }
    }
    if (end == NULL) {
      break;
    }
    component = end + 1;
  }
  return 0;
}

static void select_dynamic_linker(const char *prefix, char *loader,
                                  size_t loader_size) {
  const char *explicit_loader = getenv("REPRO_DYNAMIC_LINKER");
  if (explicit_loader != NULL && explicit_loader[0] == '/' &&
      access(explicit_loader, X_OK) == 0) {
    if (snprintf(loader, loader_size, "%s", explicit_loader) >=
        (int)loader_size) {
      errno = ENAMETOOLONG;
      fail("copy REPRO_DYNAMIC_LINKER");
    }
    return;
  }

  /* Source package actions expose their libc through LIBRARY_PATH. Prefer a
     non-Nix libc outside GCC's bootstrap prefix so the ELF interpreter and
     libc always come from the same glibc build. A mismatched loader/libc pair
     crosses GLIBC_PRIVATE and can fail before main. */
  if (find_loader_in_library_path(prefix, 0, loader, loader_size) ||
      find_loader_in_library_path(prefix, 1, loader, loader_size)) {
    return;
  }

  if (snprintf(loader, loader_size, "%s/lib/ld-linux-x86-64.so.2", prefix) >=
      (int)loader_size) {
    errno = ENAMETOOLONG;
    fail("construct bootstrap dynamic linker path");
  }
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
  char dynamic_linker[PATH_MAX];
  char linker_arg[PATH_MAX + 32];
  select_dynamic_linker(prefix, dynamic_linker, sizeof(dynamic_linker));
  if (snprintf(real_driver, sizeof(real_driver), "%s/bin/%s", prefix,
               REAL_DRIVER) >= (int)sizeof(real_driver) ||
      snprintf(sysroot_arg, sizeof(sysroot_arg),
               "--sysroot=%s/lib/bootstrap-sysroot", prefix) >=
          (int)sizeof(sysroot_arg) ||
      snprintf(linker_arg, sizeof(linker_arg),
               "-Wl,--dynamic-linker=%s", dynamic_linker) >=
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
