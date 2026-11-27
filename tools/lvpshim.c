/*
 * lvpshim — LD_PRELOAD para a prova LOCAL em Vulkan/lavapipe neste host
 * aarch64/proot (docs/ORACULO.md, "Vulkan local: workaround medido, não
 * portátil"). Não é requisito do jogo nem do CI.
 *
 * Por quê: o llvmpipe detecta a CPU do host e emite instruções (SVE) que o
 * kernel não expõe → SIGILL (sinal 4). O shim força o nome da CPU do LLVM
 * (SHIM_MCPU, padrão cortex-a76), deixa trocar as features (SHIM_FEATS, ex.
 * '-sve,-sve2'), impede o llvmpipe de capturar SIGILL e, se um SIGILL ainda
 * vier, imprime onde foi (biblioteca/símbolo) e sai com 99.
 *
 * Compilar (o .so é binário local, FORA do git):
 *   mkdir -p ~/tmp/lvpshim && gcc -shared -fPIC -O2 -o ~/tmp/lvpshim/shim.so tools/lvpshim.c -ldl
 */
#define _GNU_SOURCE
#include <stdlib.h>
#include <string.h>
#include <signal.h>
#include <stdio.h>
#include <dlfcn.h>
#include <ucontext.h>
#include <unistd.h>
typedef struct { const char *p; unsigned long n; } SR;
SR _ZN4llvm3sys14getHostCPUNameEv(void) {
  const char *c = getenv("SHIM_MCPU"); if (!c) c = "cortex-a76";

  SR r = { c, strlen(c) }; return r;
}
static void ill(int s, siginfo_t *si, void *uc) {
  ucontext_t *u = uc; unsigned long pc = u->uc_mcontext.pc;
  Dl_info d; memset(&d,0,sizeof d); dladdr((void*)pc, &d);
  fprintf(stderr, "SHIM SIGILL pc=%lx insn=%08x lib=%s sym=%s\n", pc, *(unsigned*)pc, d.dli_fname?d.dli_fname:"?", d.dli_sname?d.dli_sname:"?");
  _exit(99);
}
__attribute__((constructor)) static void ini(void) {
  struct sigaction sa; memset(&sa,0,sizeof sa); sa.sa_sigaction=ill; sa.sa_flags=SA_SIGINFO; sigaction(SIGILL,&sa,0);
}
typedef void (*sh)(int);
sh signal(int s, sh h) {
  static sh (*real)(int, sh); if(!real) real=dlsym(RTLD_NEXT,"signal");
  if (s==SIGILL) return 0;
  return real(s,h);
}
char *LLVMGetHostCPUFeatures(void) {
  static char *(*real)(void); if(!real) real=dlsym(RTLD_NEXT,"LLVMGetHostCPUFeatures");
  char *f = real ? real() : strdup("");
  static int once; if(!once++) fprintf(stderr,"SHIM feats: %s\n", f);
  const char *x = getenv("SHIM_FEATS"); if (x) { free(f); return strdup(x); }
  return f;
}
char *LLVMGetHostCPUName(void) {
  const char *c = getenv("SHIM_MCPU"); if (!c) c = "cortex-a76";
  return strdup(c);
}
