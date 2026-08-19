/* Cache-name comparison for the dynamically linked ldconfig variant.
   Copyright (C) 1996-2025 Free Software Foundation, Inc.
   This file is part of the GNU C Library.

   The GNU C Library is free software; you can redistribute it and/or
   modify it under the terms of the GNU Lesser General Public
   License as published by the Free Software Foundation; either
   version 2.1 of the License, or (at your option) any later version.

   The GNU C Library is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
   Lesser General Public License for more details.

   You should have received a copy of the GNU Lesser General Public
   License along with the GNU C Library; if not, see
   <https://www.gnu.org/licenses/>.  */

/* This implementation is kept in sync with elf/dl-cache.c. The dynamic
   loader keeps its private copy, while ldconfig needs a directly linked copy
   because the symbol is intentionally hidden from glibc's public ABI.  */
int
_dl_cache_libcmp (const char *p1, const char *p2)
{
  while (*p1 != '\0')
    {
      if (*p1 >= '0' && *p1 <= '9')
        {
          if (*p2 >= '0' && *p2 <= '9')
            {
              int val1;
              int val2;

              val1 = *p1++ - '0';
              val2 = *p2++ - '0';
              while (*p1 >= '0' && *p1 <= '9')
                val1 = val1 * 10 + *p1++ - '0';
              while (*p2 >= '0' && *p2 <= '9')
                val2 = val2 * 10 + *p2++ - '0';
              if (val1 != val2)
                return val1 - val2;
            }
          else
            return 1;
        }
      else if (*p2 >= '0' && *p2 <= '9')
        return -1;
      else if (*p1 != *p2)
        return *p1 - *p2;
      else
        {
          ++p1;
          ++p2;
        }
    }
  return *p1 - *p2;
}
