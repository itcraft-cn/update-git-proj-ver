project(lib-b VERSION 1.0.999 LANGUAGES C) # managed by updgitver
add_library(lib-b STATIC b.c)
# one-way reference: lib-b links lib-a
target_link_libraries(lib-b PRIVATE lib-a)
