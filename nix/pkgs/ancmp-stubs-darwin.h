/* Stub ancmp headers for Darwin builds */
#ifndef ANCMP_STUBS_DARWIN_H
#define ANCMP_STUBS_DARWIN_H

#ifdef __APPLE__

#include <stddef.h>
#include <dlfcn.h>

/* Stub android_dlsym - just use native dlsym */
static inline void *android_dlsym(void *handle, const char *symbol) {
    return dlsym(handle ? handle : RTLD_DEFAULT, symbol);
}

/* Stub android_dlopen - use native dlopen */
static inline void *android_dlopen(const char *filename, int flag) {
    return dlopen(filename, RTLD_LAZY);
}

/* Stub android_dlclose */
static inline int android_dlclose(void *handle) {
    return dlclose(handle);
}

/* Stub android_malloc/calloc/realloc/free - use native versions */
#define android_malloc malloc
#define android_calloc calloc
#define android_realloc realloc
#define android_free free

#endif /* __APPLE__ */

#endif /* ANCMP_STUBS_DARWIN_H */

