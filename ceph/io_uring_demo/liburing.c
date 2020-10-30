#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <stdio.h>
#include <liburing.h>

#define ENTRIES        4

// gcc liburing.c -luring
int main(int argc, char *argv[])
{
    struct io_uring ring;
    struct io_uring_sqe *sqe;
    struct io_uring_cqe *cqe;
    struct iovec iov = {
        .iov_base = "Hello World",
        .iov_len = strlen("Hello World"),
    };
    int fd, ret;

    if (argc != 2) {
        printf("%s: <testfile>\n", argv[0]);
        return 1;
    }

    /* setup io_uring and do mmap */
    ret = io_uring_queue_init(ENTRIES, &ring, 0);
    if (ret < 0) {
        printf("io_uring_queue_init: %s\n", strerror(-ret));
        return 1;
    }

    fd = open("testfile", O_WRONLY | O_CREAT);
    if (fd < 0) {
        printf("open failed\n");
        ret = 1;
        goto exit;
    }

    /* get an sqe and fill in a WRITEV operation */
    sqe = io_uring_get_sqe(&ring);
    if (!sqe) {
        printf("io_uring_get_sqe failed\n");
        ret = 1;
        goto out;
    }

    io_uring_prep_writev(sqe, fd, &iov, 1, 0);

    /* tell the kernel we have an sqe ready for consumption */
    ret = io_uring_submit(&ring);
    if (ret < 0) {
        printf("io_uring_submit: %s\n", strerror(-ret));
        goto out;
    }

    /* wait for the sqe to complete */
    while (1) {
        io_uring_peek_cqe(&ring, &cqe);
        if (!cqe) {
            printf("Not completed, waiting...\n");
            usleep(1);
        } else {
            printf("Completed\n");
            break;
        }
    }

    /* read and process cqe event */
    io_uring_cqe_seen(&ring, cqe);
out:
    close(fd);
exit:
    /* tear down */
    io_uring_queue_exit(&ring);
    return ret;
}
