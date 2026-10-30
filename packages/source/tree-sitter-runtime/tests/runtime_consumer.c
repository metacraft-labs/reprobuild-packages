#ifndef TREE_SITTER_HEADER
#error "The control requires the exact produced Tree-sitter header"
#endif
#include TREE_SITTER_HEADER

int main(void) {
  TSParser *parser = ts_parser_new();
  if (!parser) {
    return 1;
  }
  ts_parser_delete(parser);
  return 0;
}
