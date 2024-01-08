#include <fcntl.h>
#include <sys/mman.h>
#include <errno.h>
#include <stdio.h>
#include <unistd.h>
unsigned long long MAP_LENGTH = 10 * 1024 * 1024 * (long long)1024; // 10GB
int main()
{
   int fd;
   void * addr;
   char node[256] = "/dev/hugepages/hugepage1";
   /* 1. 创建一个 Hugetlb 文件系统的文件 */
   fd = open(node, O_CREAT|O_RDWR);
   if (fd < 0) {
       perror("open()");
       return -1;
   }
   /* 2. 把虚拟内存映射到 Hugetlb 文件系统的文件中 */
   addr = mmap(0, MAP_LENGTH, PROT_READ|PROT_WRITE, MAP_SHARED, fd, 0);
   if (addr == MAP_FAILED) {
       perror("mmap()");
       close(fd);
       unlink(node);
       return -1;
   }
   printf("This is HugePages example,%p\n", addr);

   sleep(10);

   /* 3. 使用完成后，解除映射关系 */
   munmap(addr, MAP_LENGTH);
   close(fd);
   unlink("node");
   return 0;
}
