int main() {
  volatile int hello = 0;
  while (1) {
    __asm volatile ("nop");
  }
}
