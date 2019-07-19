class ZCL_CLASS_DECORATOR definition
  public
  final
  create public .

public section.

  methods EXPOSE
    importing
      !IV_IMPL type STRING
      !IT_PARAMS type ABAP_PARMBIND_TAB optional
    returning
      value(RR_OBJECT) type ref to OBJECT .
  methods ADD_GET_SET
    importing
      !IV_IMPL type STRING
      !IT_PARAMS type ABAP_PARMBIND_TAB optional
    returning
      value(RR_OBJECT) type ref to OBJECT .
  protected section.

private section.

  methods DELETE_LINE
    importing
      !IV_PATTERN type STRING
    changing
      !CT_SOURCE type STRINGTAB .
  methods PREPARE_CLASS_DEFINITION
    changing
      !CT_SOURCE type STRINGTAB .
  methods GET_SOURCE_CODE
    importing
      !IV_IMPL type SEOCLSKEY
    returning
      value(RT_SOURCE) type STRINGTAB .
  methods CREATE_OBJECT
    importing
      !IV_NAME type STRING
      !IT_PARAMS type ABAP_PARMBIND_TAB optional
    returning
      value(RR_OBJECT) type ref to OBJECT .
  methods CHECK_SYNTAX
    importing
      !IT_SOURCE type STRINGTAB
    returning
      value(RT_ERRORS) type ETSYNTAX_ERROR_TABTYPE .
  methods GENERATE_OBJECT
    importing
      !IT_SOURCE type STRINGTAB
      !IV_NAME type STRING
      !IT_PARAMS type ABAP_PARMBIND_TAB optional
    returning
      value(RR_OBJECT) type ref to OBJECT
    raising
      CX_CODE_GENERATION_ERROR .
ENDCLASS.



CLASS ZCL_CLASS_DECORATOR IMPLEMENTATION.


  method add_get_set.

    "--- Returns the class with additional generic getters and setters.

    "--- Get the source code...
    data(lt_source) = me->get_source_code( conv #( iv_impl ) ).

    "--- change the definition a little...
    me->prepare_class_definition( changing ct_source = lt_source ).

    "--- insert some new definitions....
    insert lines of value stringtab( ( |methods: get_attr importing !iv_attr type string returning value(rr_data) type ref to zcl_boxed_data.| )
                                     ( |methods: set_attr importing !iv_attr type string iv_val type any.|                                    )
                                     ( |class-data: gr_ref type ref to data.|                                                                 )
                                   ) into lt_source index 4.

    "--- delete endclass statement...
    delete lt_source index lines( lt_source ).

    "--- hack in our implementations...
    append lines of value stringtab( ( |method: get_attr.|                                )
                                     ( |assign me->(iv_attr) to field-symbol(<fs_data>).| )
                                     ( |rr_data = zcl_boxed_packer=>box( <fs_data> ).|    )
                                     ( |endmethod.|                                       )
                                     ( |method: set_attr.|                                )
                                     ( |assign me->(iv_attr) to field-symbol(<fs_data>).| )
                                     ( |<fs_data> = iv_val.|                              )
                                     ( |endmethod.|                                       )
                                     ( |endclass.| )                                      ) to lt_source.

    rr_object = me->generate_object( iv_name   = iv_impl
                                     it_source = lt_source
                                     it_params = it_params ).

  endmethod.


  method check_syntax.

    "--- checks an internal table of source code for syntax errors

    data: lv_mess type char255, lin type i, lv_word type char255, lv_line type c.

    syntax-check
      for it_source
      program 'DUMMY'
      message lv_mess
      line lv_line
      word lv_word
      id 'ERR' table rt_errors.

  endmethod.


  method create_object.

    "--- Creates the object instance

    if it_params is not initial.
      create object rr_object type (iv_name)
      parameter-table it_params.

    else.
      create object rr_object type (iv_name).
    endif.
  endmethod.


  method delete_line.

    "--- Deletes the first line in an internal table that mattaches a pattern

    loop at ct_source assigning field-symbol(<fs_line>) where table_line cp iv_pattern.
      delete ct_source index sy-tabix.
      return.
    endloop.
  endmethod.


  method expose.

    "--- Alters the existing source code of a class to generate an object with 100% public visibility

    "--- retrieve existing source of iv_impl...
    data(lt_source) = me->get_source_code( conv #( iv_impl ) ).

    "--- change the definition a little...
    me->prepare_class_definition( changing ct_source = lt_source ).

    "--- delete the protected & private sections, making it all public...
    me->delete_line( exporting iv_pattern = 'protected section*' changing ct_source = lt_source ).
    me->delete_line( exporting iv_pattern = 'private section*'   changing ct_source = lt_source ).

    rr_object = me->generate_object( iv_name   = iv_impl
                                     it_source = lt_source
                                     it_params = it_params ).
  endmethod.


  method generate_object.

    "--- generates a class definition and runtime and returns an instance of said class

    data(lt_syntax_errors) = me->check_syntax( it_source ).

    if lt_syntax_errors is initial.

      "--- Generate...
      generate subroutine pool it_source name data(lv_prog_name).
      data(lv_class_name) = '\PROGRAM=' && lv_prog_name && '\CLASS=' && iv_name.

      "--- Instantiate... (returns type ref to object).
      rr_object = me->create_object( iv_name   = lv_class_name
                                     it_params = it_params ) .

    else.
      raise exception type cx_code_generation_error.
    endif.
  endmethod.


  method get_source_code.

    "--- Retrieves the existing source code of a class

    data(lr_source_reader) = new cl_oo_source( clskey = iv_impl ). "--- iv_impl = class name
    lr_source_reader->read( ).
    rt_source = lr_source_reader->source.
  endmethod.


  method prepare_class_definition.

    "--- Changes the class definition to make it 'generate subroutine pool' friendly.

    "--- change the class definition...
    "--- public, final, create public etc all need to go
    "--- for generate subroutine to work...

    data lt_match_results type table of match_result.

    "--- add a full stop at the class definition line...
    loop at ct_source assigning field-symbol(<fs_line>) where table_line cp 'class*definition*'.
      <fs_line> = <fs_line> && '.'.
    endloop.

    "--- delete out everything else (final, create public etc)
    find 'public section' in table ct_source results lt_match_results.
    data(lv_public_section_begins) = lt_match_results[ 1 ]-line.
    delete ct_source from 2 to lt_match_results[ 1 ]-line - 1.

    "--- This needs to be the first line for generate subroutine pool
    insert 'PROGRAM.' into ct_source index 1.

  endmethod.
ENDCLASS.
