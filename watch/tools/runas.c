#define _GNU_SOURCE
#include <grp.h>
#include <stdlib.h>
#include <unistd.h>
/* runas <uid> <gid> <cmd...>: supplementary groups 995 (privileged) + uid */
int main(int argc, char **argv) {
    gid_t groups[] = { 995, (gid_t)atoi(argv[1]) };
    setgroups(2, groups); setgid(atoi(argv[2])); setuid(atoi(argv[1]));
    execvp(argv[3], argv + 3); return 127;
}
