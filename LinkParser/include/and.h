void       free_AND_tables(Sentence sent);
void       print_AND_statistics(Sentence sent);
void       init_andable_hash_table(Dictionary dict);
void       free_andable_hash_table(Dictionary dict);
void       initialize_conjunction_tables(Sentence sent);
int        is_canonical_linkage(Sentence sent);
int        set_has_fat_down(Sentence sent);
Disjunct * build_AND_disjunct_list(Sentence sent, char *);
Disjunct * build_COMMA_disjunct_list(Sentence sent);
Disjunct * explode_disjunct_list(Sentence sent, Disjunct *);
void       build_conjunction_tables(Sentence);
char *     intersect_strings(Sentence sent, char * s, char * t);
void       compute_pp_link_array_connectors(Sentence sent, Sublinkage *sublinkage);
