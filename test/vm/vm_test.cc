#include <gtest/gtest.h>
#include "third_party/zircon_c/vm/pmm_arena.h"
#include "third_party/zircon_c/vm/vmo_bootstrap.h"
#include "third_party/zircon_c/vm/page_fault.h"

class VmTest : public ::testing::Test {
protected:
  void SetUp() override {
    pmm_arena_init(&arena_, 0x1000000, 4096 * 100);
  }

  void TearDown() override {
    if (arena_.page_array) {
      free(arena_.page_array);
    }
  }

  pmm_arena_t arena_;
};

TEST_F(VmTest, PmmArenaInitialization) {
  EXPECT_EQ(arena_.base, 0x1000000);
  EXPECT_EQ(arena_.size, 4096 * 100);
  EXPECT_EQ(pmm_arena_free_count(&arena_), 100);
}

TEST_F(VmTest, PmmArenaAllocatePage) {
  vm_page_t* page = nullptr;
  zx_status_t status = pmm_arena_alloc_page(&arena_, &page);
  
  ASSERT_EQ(status, ZX_OK);
  ASSERT_NE(page, nullptr);
  EXPECT_EQ(page->state, VM_PAGE_STATE_ALLOCATED);
  EXPECT_EQ(page->ref_count, 1);
  EXPECT_EQ(pmm_arena_free_count(&arena_), 99);
}

TEST_F(VmTest, PmmArenaFreePage) {
  vm_page_t* page = nullptr;
  pmm_arena_alloc_page(&arena_, &page);
  
  zx_status_t status = pmm_arena_free_page(&arena_, page);
  
  EXPECT_EQ(status, ZX_OK);
  EXPECT_EQ(page->state, VM_PAGE_STATE_FREE);
  EXPECT_EQ(pmm_arena_free_count(&arena_), 100);
}

TEST_F(VmTest, PmmArenaMultipleAllocations) {
  vm_page_t* pages[10];
  
  for (int i = 0; i < 10; i++) {
    zx_status_t status = pmm_arena_alloc_page(&arena_, &pages[i]);
    ASSERT_EQ(status, ZX_OK);
  }
  
  EXPECT_EQ(pmm_arena_free_count(&arena_), 90);
  
  for (int i = 0; i < 10; i++) {
    pmm_arena_free_page(&arena_, pages[i]);
  }
  
  EXPECT_EQ(pmm_arena_free_count(&arena_), 100);
}

TEST_F(VmTest, PmmArenaExhaustion) {
  vm_page_t* page = nullptr;
  
  for (size_t i = 0; i < 100; i++) {
    zx_status_t status = pmm_arena_alloc_page(&arena_, &page);
    ASSERT_EQ(status, ZX_OK);
  }
  
  zx_status_t status = pmm_arena_alloc_page(&arena_, &page);
  EXPECT_EQ(status, ZX_ERR_NO_MEMORY);
}

TEST_F(VmTest, VmoBootstrapInitialization) {
  vmo_t vmo;
  zx_status_t status = vmo_bootstrap_init(&vmo, &arena_, 4096 * 10);
  
  ASSERT_EQ(status, ZX_OK);
  EXPECT_EQ(vmo.size, 4096 * 10);
  EXPECT_EQ(vmo.page_count, 10);
  ASSERT_NE(vmo.pages, nullptr);
  
  vmo_bootstrap_destroy(&vmo, &arena_);
}

TEST_F(VmTest, VmoBootstrapCommitPage) {
  vmo_t vmo;
  vmo_bootstrap_init(&vmo, &arena_, 4096 * 5);
  
  size_t initial_free = pmm_arena_free_count(&arena_);
  
  zx_status_t status = vmo_bootstrap_commit_page(&vmo, &arena_, 0);
  EXPECT_EQ(status, ZX_OK);
  EXPECT_EQ(pmm_arena_free_count(&arena_), initial_free - 1);
  EXPECT_NE(vmo.pages[0], nullptr);
  
  status = vmo_bootstrap_commit_page(&vmo, &arena_, 0);
  EXPECT_EQ(status, ZX_OK);
  EXPECT_EQ(pmm_arena_free_count(&arena_), initial_free - 1);
  
  vmo_bootstrap_destroy(&vmo, &arena_);
}

TEST_F(VmTest, VmoBootstrapMultiplePages) {
  vmo_t vmo;
  vmo_bootstrap_init(&vmo, &arena_, 4096 * 5);
  
  for (size_t i = 0; i < 5; i++) {
    zx_status_t status = vmo_bootstrap_commit_page(&vmo, &arena_, i);
    ASSERT_EQ(status, ZX_OK);
  }
  
  for (size_t i = 0; i < 5; i++) {
    EXPECT_NE(vmo.pages[i], nullptr);
  }
  
  vmo_bootstrap_destroy(&vmo, &arena_);
  EXPECT_EQ(pmm_arena_free_count(&arena_), 100);
}

TEST_F(VmTest, PageFaultHandlerInitialization) {
  vmo_t vmo;
  vmo_bootstrap_init(&vmo, &arena_, 4096 * 10);
  
  page_fault_handler_t handler;
  zx_status_t status = page_fault_handler_init(&handler, &vmo, &arena_);
  
  EXPECT_EQ(status, ZX_OK);
  EXPECT_EQ(handler.vmo, &vmo);
  EXPECT_EQ(handler.arena, &arena_);
  
  vmo_bootstrap_destroy(&vmo, &arena_);
}

TEST_F(VmTest, PageFaultHandleCommitsPage) {
  vmo_t vmo;
  vmo_bootstrap_init(&vmo, &arena_, 4096 * 10);
  
  page_fault_handler_t handler;
  page_fault_handler_init(&handler, &vmo, &arena_);
  
  vaddr_t fault_addr = 4096 * 3;
  uint32_t flags = PAGE_FAULT_FLAG_READ | PAGE_FAULT_FLAG_USER;
  
  EXPECT_EQ(vmo.pages[3], nullptr);
  
  zx_status_t status = page_fault_handle(&handler, fault_addr, flags);
  EXPECT_EQ(status, ZX_OK);
  EXPECT_NE(vmo.pages[3], nullptr);
  
  vmo_bootstrap_destroy(&vmo, &arena_);
}

TEST_F(VmTest, PageFaultOutOfBounds) {
  vmo_t vmo;
  vmo_bootstrap_init(&vmo, &arena_, 4096 * 10);
  
  page_fault_handler_t handler;
  page_fault_handler_init(&handler, &vmo, &arena_);
  
  vaddr_t fault_addr = 4096 * 20;
  uint32_t flags = PAGE_FAULT_FLAG_READ | PAGE_FAULT_FLAG_USER;
  
  zx_status_t status = page_fault_handle(&handler, fault_addr, flags);
  EXPECT_EQ(status, ZX_ERR_NOT_FOUND);
  
  vmo_bootstrap_destroy(&vmo, &arena_);
}

TEST_F(VmTest, PageFaultInvalidFlags) {
  vmo_t vmo;
  vmo_bootstrap_init(&vmo, &arena_, 4096 * 10);
  
  page_fault_handler_t handler;
  page_fault_handler_init(&handler, &vmo, &arena_);
  
  vaddr_t fault_addr = 0;
  uint32_t flags = PAGE_FAULT_FLAG_WRITE;
  
  zx_status_t status = page_fault_handle(&handler, fault_addr, flags);
  EXPECT_EQ(status, ZX_ERR_INVALID_ARGS);
  
  vmo_bootstrap_destroy(&vmo, &arena_);
}

TEST_F(VmTest, ReferenceCountingBasic) {
  vm_page_t* page = nullptr;
  pmm_arena_alloc_page(&arena_, &page);
  
  EXPECT_EQ(page->ref_count, 1);
  
  page->ref_count++;
  EXPECT_EQ(page->ref_count, 2);
  
  zx_status_t status = pmm_arena_free_page(&arena_, page);
  EXPECT_EQ(status, ZX_OK);
  EXPECT_EQ(page->ref_count, 1);
  EXPECT_EQ(page->state, VM_PAGE_STATE_ALLOCATED);
  
  status = pmm_arena_free_page(&arena_, page);
  EXPECT_EQ(status, ZX_OK);
  EXPECT_EQ(page->ref_count, 0);
  EXPECT_EQ(page->state, VM_PAGE_STATE_FREE);
}
