class lcl_tester definition deferred.
class zcl_class_decorator definition local friends lcl_tester.

class lcl_tester definition for testing
  duration short
  risk level harmless.

  private section.
    data: lr_decorator type ref to zcl_class_decorator.

    methods: setup.

    "--- Test methods...

    "--- Tests we can expose private attributes and methods...
    methods: expose_method for testing.
    methods: expose_attribute for testing.

    "--- Test we can add and call generic getters and setters...
    methods: call_added_getter for testing.
    methods: call_added_setter for testing.
    methods: add_getter_param_name for testing.
    methods: add_getter for testing.
    methods: add_setter for testing.
    methods: add_setter_param_name for testing.

    "--- Helper methods...
    methods: check_method_exists importing !iv_name type string.
    methods: check_method_param_name importing !iv_meth_name type string !iv_param_name type string.

endclass.       "lcl_Tester


class lcl_tester implementation.

  method setup.
    lr_decorator = new zcl_class_decorator( ).
  endmethod.

  method expose_method.

    "--- Tests that we can publicly expose and call a private method of an existing class

    "--- 'GET_RECORDS_COUNT' is a private method on CL_WDR_TEST_ATTRIBUTE_FILTER
    data lr_count type ref to data.

    data(lr_obj) = lr_decorator->expose( 'CL_WDR_TEST_ATTRIBUTE_FILTER' ).
    call method lr_obj->('GET_RECORDS_COUNT') exporting where_clause = 'CARRID IS NOT NULL' receiving records_count = lr_count.
    cl_abap_unit_assert=>assert_not_initial( act = lr_count
                                             msg = 'Expected a result back from dynamic method call '  ).
  endmethod.

  method expose_attribute.

    "--- Tests that we can access a private attribute of an existing class...

    "--- GL_LANGU is a private attribute on CL_SOTR
    data(lr_obj) = new zcl_class_decorator( )->expose( 'CL_SOTR' ).

    assign lr_obj->('GL_LANGU') to field-symbol(<fs_val>).
    cl_abap_unit_assert=>assert_subrc( exp = 0 ).
    cl_abap_unit_assert=>assert_not_initial( act = <fs_val>
                                             msg = 'Expected fs val to have a value and be assigned'  ).

  endmethod.

  method: call_added_getter.

    "--- Tests we can call appended getter on private attribute

    "--- GL_LANGU is a private attribute on CL_SOTR
    data lr_result type ref to zcl_boxed_data.

    data(lr_obj) = lr_decorator->add_get_set( 'CL_SOTR' ).
    call method lr_obj->('GET_ATTR') exporting iv_attr = 'GL_LANGU' receiving rr_data = lr_result.

    cl_abap_unit_assert=>assert_bound( lr_result ).
    cl_abap_unit_assert=>assert_equals( exp = 'E'
                                        act = cast zcl_boxed_element( lr_result )->to_string( ) ).

  endmethod.

  method: call_added_setter.

    "--- Tests we can set private attribute to something else

    "--- GL_LANGU is a private attribute on CL_SOTR
    data lr_result type ref to zcl_boxed_data.

    data(lr_obj) = lr_decorator->add_get_set( 'CL_SOTR' ).
    call method lr_obj->('SET_ATTR') exporting iv_attr = 'GL_LANGU' iv_val = 'Z'.
    call method lr_obj->('GET_ATTR') exporting iv_attr = 'GL_LANGU' receiving rr_data = lr_result.

    cl_abap_unit_assert=>assert_equals( exp = 'Z'
                                        act = cast zcl_boxed_element( lr_result )->to_string( ) ).

  endmethod.


  method check_method_exists.

    "--- Tests that a method exists after calling add_get_set

    data lr_descr type ref to cl_abap_objectdescr.
    data(lr_obj) = me->lr_decorator->add_get_set( 'CL_ABAPCG_NWA_UTIL' ).
    lr_descr    ?= cl_abap_objectdescr=>describe_by_object_ref( lr_obj ).

    data(ls_method_details) = value abap_methdescr( lr_descr->methods[ name = |{ iv_name case = upper }| ] optional  ).

    cl_abap_unit_assert=>assert_not_initial( act = ls_method_details
                                             msg = 'Expected a method called ' && iv_name && 'to exist' ).

  endmethod.

  method check_method_param_name.

    "--- Tests that a param on a method exists after calling add_get_set

    data(lr_obj)     = lr_decorator->add_get_set( 'CL_ABAPCG_NWA_UTIL' ).
    data(lr_descr)   = cast cl_abap_classdescr( cl_abap_classdescr=>describe_by_object_ref( lr_obj ) ).
    data(lr_p_descr) = lr_descr->get_method_parameter_type( p_method_name    = iv_meth_name
                                                            p_parameter_name = iv_param_name ).

    cl_abap_unit_assert=>assert_bound( act = lr_p_descr
                                       msg = 'Expected a getter with param name ' && iv_param_name ).

  endmethod.

  method add_getter.

    "--- Tests that 'get_attr' is added to the returned object after calling add_get_set

    me->check_method_exists( 'get_attr' ).
  endmethod.

  method add_getter_param_name.

    "--- Tests that get_attr has a param name
    me->check_method_param_name( iv_meth_name = 'get_attr'
                                 iv_param_name = 'iv_attr' ).
  endmethod.

  method add_setter.

    "--- Tests that setter is added after calling add_get_set

    me->check_method_exists( 'set_attr' ).
  endmethod.

  method add_setter_param_name.

    "--- Tests param name exists on setter

    me->check_method_param_name( iv_meth_name = 'set_attr'
                                 iv_param_name = 'iv_attr' ).
  endmethod.

endclass.
