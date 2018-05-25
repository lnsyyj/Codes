/**
 * gcc direct_io_write_file.c -o direct_io_write_file -D_GNU_SOURCE
 */
#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <sys/file.h>
#include <sys/types.h>
#include <sys/stat.h> 
#include <string.h>
#include <unistd.h>
#define BUF_SIZE 1024
#define TIMES 100
 
int main(int argc, char * argv[])
{
    int fd;
    int ret;
    unsigned char *buf;
    //ret = posix_memalign((void **)&buf, 512, BUF_SIZE);
    ret = posix_memalign((void **)&buf, 512, BUF_SIZE);
    if (ret) {
        perror("posix_memalign failed");
        exit(1);
    }
 
    memset(buf, 'c', BUF_SIZE);
    fd = open("./direct_io.data", O_WRONLY | O_DIRECT | O_CREAT, 0755);
    if (fd < 0){
        perror("open ./direct_io.data failed");
        exit(1);
    }
    int i = 1;
    do {
        //memset(buf, i, BUF_SIZE);
        //memset(buf, 1, BUF_SIZE);
        ret = write(fd, buf, BUF_SIZE);
        printf("%d\n",i);
        if (ret < 0) {
            perror("write ./direct_io.data failed");
        }
       sleep(1);
       i++;
    } while (i < (TIMES));
 
    free(buf);
    close(fd);
}
