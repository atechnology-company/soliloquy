#include <stdio.h>
#include <stdlib.h>
#include <assert.h>
#include "third_party/zircon_c/vm/pmm_arena.h"
#include "third_party/zircon_c/vm/vmo_bootstrap.h"
#include "third_party/zircon_c/vm/page_fault.h"

static int tests_passed = 0;
static int tests_failed = 0;

#define TEST(name) \
    static void test_##name(); \
    static void run_test_##name() { \
        printf("Running test: %s\n", #name); \
        test_##name(); \
        tests_passed++; \
        printf("  PASSED\n"); \
    } \
    static void test_##name()

#define EXPECT_EQ(a, b) \
    do { \
        if ((a) != (b)) { \
            printf("  FAILED: Expected %ld == %ld at line %d\n", (long)(a), (long)(b), __LINE__); \
            tests_failed++; \
            return; \
        } \
    } while (0)

#define EXPECT_NE(a, b) \
    do { \
        if ((a) == (b)) { \
            printf("  FAILED: Expected %ld != %ld at line %d\n", (long)(a), (long)(b), __LINE__); \
            tests_failed++; \
            return; \
        } \
    } while (0)

TEST(pmm_arena_initialization) {
    pmm_arena_t arena;
    zx_status_t status = pmm_arena_init(&arena, 0x1000000, 4096 * 100);
    
    EXPECT_EQ(status, ZX_OK);
    EXPECT_EQ(arena.base, 0x1000000);
    EXPECT_EQ(arena.size, 4096 * 100);
    EXPECT_EQ(pmm_arena_free_count(&arena), 100);
    
    free(arena.page_array);
}

TEST(pmm_arena_allocate_page) {
    pmm_arena_t arena;
    pmm_arena_init(&arena, 0x1000000, 4096 * 100);
    
    vm_page_t* page = NULL;
    zx_status_t status = pmm_arena_alloc_page(&arena, &page);
    
    EXPECT_EQ(status, ZX_OK);
    EXPECT_NE((long)page, 0);
    EXPECT_EQ(page->state, VM_PAGE_STATE_ALLOCATED);
    EXPECT_EQ(page->ref_count, 1);
    EXPECT_EQ(pmm_arena_free_count(&arena), 99);
    
    free(arena.page_array);
}

TEST(pmm_arena_free_page) {
    pmm_arena_t arena;
    pmm_arena_init(&arena, 0x1000000, 4096 * 100);
    
    vm_page_t* page = NULL;
    pmm_arena_alloc_page(&arena, &page);
    
    zx_status_t status = pmm_arena_free_page(&arena, page);
    
    EXPECT_EQ(status, ZX_OK);
    EXPECT_EQ(page->state, VM_PAGE_STATE_FREE);
    EXPECT_EQ(pmm_arena_free_count(&arena), 100);
    
    free(arena.page_array);
}

TEST(pmm_arena_exhaustion) {
    pmm_arena_t arena;
    pmm_arena_init(&arena, 0x1000000, 4096 * 10);
    
    vm_page_t* page = NULL;
    
    for (size_t i = 0; i < 10; i++) {
        zx_status_t status = pmm_arena_alloc_page(&arena, &page);
        EXPECT_EQ(status, ZX_OK);
    }
    
    zx_status_t status = pmm_arena_alloc_page(&arena, &page);
    EXPECT_EQ(status, ZX_ERR_NO_MEMORY);
    
    free(arena.page_array);
}

TEST(vmo_bootstrap_initialization) {
    pmm_arena_t arena;
    pmm_arena_init(&arena, 0x1000000, 4096 * 100);
    
    vmo_t vmo;
    zx_status_t status = vmo_bootstrap_init(&vmo, &arena, 4096 * 10);
    
    EXPECT_EQ(status, ZX_OK);
    EXPECT_EQ(vmo.size, 4096 * 10);
    EXPECT_EQ(vmo.page_count, 10);
    EXPECT_NE((long)vmo.pages, 0);
    
    vmo_bootstrap_destroy(&vmo, &arena);
    free(arena.page_array);
}

TEST(vmo_bootstrap_commit_page) {
    pmm_arena_t arena;
    pmm_arena_init(&arena, 0x1000000, 4096 * 100);
    
    vmo_t vmo;
    vmo_bootstrap_init(&vmo, &arena, 4096 * 5);
    
    size_t initial_free = pmm_arena_free_count(&arena);
    
    zx_status_t status = vmo_bootstrap_commit_page(&vmo, &arena, 0);
    EXPECT_EQ(status, ZX_OK);
    EXPECT_EQ(pmm_arena_free_count(&arena), initial_free - 1);
    EXPECT_NE((long)vmo.pages[0], 0);
    
    status = vmo_bootstrap_commit_page(&vmo, &arena, 0);
    EXPECT_EQ(status, ZX_OK);
    EXPECT_EQ(pmm_arena_free_count(&arena), initial_free - 1);
    
    vmo_bootstrap_destroy(&vmo, &arena);
    free(arena.page_array);
}

TEST(page_fault_handler_commits_page) {
    pmm_arena_t arena;
    pmm_arena_init(&arena, 0x1000000, 4096 * 100);
    
    vmo_t vmo;
    vmo_bootstrap_init(&vmo, &arena, 4096 * 10);
    
    page_fault_handler_t handler;
    page_fault_handler_init(&handler, &vmo, &arena);
    
    vaddr_t fault_addr = 4096 * 3;
    uint32_t flags = PAGE_FAULT_FLAG_READ | PAGE_FAULT_FLAG_USER;
    
    EXPECT_EQ((long)vmo.pages[3], 0);
    
    zx_status_t status = page_fault_handle(&handler, fault_addr, flags);
    EXPECT_EQ(status, ZX_OK);
    EXPECT_NE((long)vmo.pages[3], 0);
    
    vmo_bootstrap_destroy(&vmo, &arena);
    free(arena.page_array);
}

TEST(page_fault_out_of_bounds) {
    pmm_arena_t arena;
    pmm_arena_init(&arena, 0x1000000, 4096 * 100);
    
    vmo_t vmo;
    vmo_bootstrap_init(&vmo, &arena, 4096 * 10);
    
    page_fault_handler_t handler;
    page_fault_handler_init(&handler, &vmo, &arena);
    
    vaddr_t fault_addr = 4096 * 20;
    uint32_t flags = PAGE_FAULT_FLAG_READ | PAGE_FAULT_FLAG_USER;
    
    zx_status_t status = page_fault_handle(&handler, fault_addr, flags);
    EXPECT_EQ(status, ZX_ERR_NOT_FOUND);
    
    vmo_bootstrap_destroy(&vmo, &arena);
    free(arena.page_array);
}

TEST(reference_counting) {
    pmm_arena_t arena;
    pmm_arena_init(&arena, 0x1000000, 4096 * 100);
    
    vm_page_t* page = NULL;
    pmm_arena_alloc_page(&arena, &page);
    
    EXPECT_EQ(page->ref_count, 1);
    
    page->ref_count++;
    EXPECT_EQ(page->ref_count, 2);
    
    zx_status_t status = pmm_arena_free_page(&arena, page);
    EXPECT_EQ(status, ZX_OK);
    EXPECT_EQ(page->ref_count, 1);
    EXPECT_EQ(page->state, VM_PAGE_STATE_ALLOCATED);
    
    status = pmm_arena_free_page(&arena, page);
    EXPECT_EQ(status, ZX_OK);
    EXPECT_EQ(page->ref_count, 0);
    EXPECT_EQ(page->state, VM_PAGE_STATE_FREE);
    
    free(arena.page_array);
}

int main() {
    printf("Running VM subsystem tests...\n\n");
    
    run_test_pmm_arena_initialization();
    run_test_pmm_arena_allocate_page();
    run_test_pmm_arena_free_page();
    run_test_pmm_arena_exhaustion();
    run_test_vmo_bootstrap_initialization();
    run_test_vmo_bootstrap_commit_page();
    run_test_page_fault_handler_commits_page();
    run_test_page_fault_out_of_bounds();
    run_test_reference_counting();
    
    printf("\n========================================\n");
    printf("Test Results:\n");
    printf("  PASSED: %d\n", tests_passed);
    printf("  FAILED: %d\n", tests_failed);
    printf("========================================\n");
    
    return tests_failed == 0 ? 0 : 1;
}
