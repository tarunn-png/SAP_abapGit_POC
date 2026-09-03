*&---------------------------------------------------------------------*
*& Report  ZENT_STR_GITHUB
*& Title   : Enterprise Purchasing Configuration & Data Extractor
*& Description: Extracts Purchasing Orgs, Groups, Vendors, Info Records,
*&              and Source Lists into ALV Grid or formatted JSON.
*&---------------------------------------------------------------------*
REPORT zent_str_github.

TABLES: t024e, t024w, lfa1, eina, eord.

*---------------------------------------------------------------------*
* SELECTION SCREEN
*---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001. " Data Filters
  SELECT-OPTIONS: s_ekorg FOR t024e-ekorg,
                  s_werks FOR t024w-werks,
                  s_lifnr FOR lfa1-lifnr,
                  s_matnr FOR eina-matnr.
SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE TEXT-002. " Datasets to Extract
  PARAMETERS: p_porg  AS CHECKBOX DEFAULT 'X',
              p_pgrp  AS CHECKBOX DEFAULT 'X',
              p_plant AS CHECKBOX DEFAULT 'X',
              p_vend  AS CHECKBOX DEFAULT 'X',
              p_info  AS CHECKBOX DEFAULT 'X',
              p_src   AS CHECKBOX DEFAULT 'X'.
SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE TEXT-003. " Output Mode
  PARAMETERS: p_alv  RADIOBUTTON GROUP r1 DEFAULT 'X',
              p_json RADIOBUTTON GROUP r1.
  PARAMETERS: p_max  TYPE i DEFAULT 5000. " Safety limit for queries
SELECTION-SCREEN END OF BLOCK b3.


*---------------------------------------------------------------------*
* CLASS DEFINITION
*---------------------------------------------------------------------*
CLASS lcl_purchasing_extractor DEFINITION FINAL.
  PUBLIC SECTION.

    TYPES:
      BEGIN OF ty_porg,
        ekorg TYPE t024e-ekorg,
        ekotx TYPE t024e-ekotx,
        bukrs TYPE t024e-bukrs,
      END OF ty_porg,

      BEGIN OF ty_pgroup,
        ekgrp TYPE t024-ekgrp,
        eknam TYPE t024-eknam,
      END OF ty_pgroup,

      BEGIN OF ty_porg_plant,
        ekorg TYPE t024w-ekorg,
        werks TYPE t024w-werks,
      END OF ty_porg_plant,

      BEGIN OF ty_vendor,
        lifnr TYPE lfa1-lifnr,
        name1 TYPE lfa1-name1,
        ktokk TYPE lfa1-ktokk,
      END OF ty_vendor,

      BEGIN OF ty_vendor_porg,
        lifnr TYPE lfm1-lifnr,
        ekorg TYPE lfm1-ekorg,
        loevm TYPE lfm1-loevm,
      END OF ty_vendor_porg,

      BEGIN OF ty_info,
        infnr TYPE eina-infnr,
        matnr TYPE eina-matnr,
        lifnr TYPE eina-lifnr,
        ekorg TYPE eine-ekorg,
        werks TYPE eine-werks,
        esokz TYPE eine-esokz,
        netpr TYPE eine-netpr,
        waers TYPE eine-waers,
      END OF ty_info,

      BEGIN OF ty_source,
        matnr TYPE eord-matnr,
        werks TYPE eord-werks,
        lifnr TYPE eord-lifnr,
        infnr TYPE eina-infnr,
        vdatu TYPE eord-vdatu,
        bdatu TYPE eord-bdatu,
        flifn TYPE eord-flifn,
      END OF ty_source,

      BEGIN OF ty_summary,
        purchasing_organizations TYPE i,
        purchasing_groups        TYPE i,
        porg_plant_assignments   TYPE i,
        vendors                  TYPE i,
        info_records             TYPE i,
        source_list_entries      TYPE i,
      END OF ty_summary,

      BEGIN OF ty_payload,
        document_type            TYPE string,
        system                   TYPE sysid,
        client                   TYPE symandt,
        generated_by             TYPE syuname,
        generated_on             TYPE dats,
        generated_at             TYPE tims,
        summary                  TYPE ty_summary,
        purchasing_organizations TYPE STANDARD TABLE OF ty_porg WITH EMPTY KEY,
        purchasing_groups        TYPE STANDARD TABLE OF ty_pgroup WITH EMPTY KEY,
        purchasing_org_plant     TYPE STANDARD TABLE OF ty_porg_plant WITH EMPTY KEY,
        vendors                  TYPE STANDARD TABLE OF ty_vendor WITH EMPTY KEY,
        vendor_purchasing_org    TYPE STANDARD TABLE OF ty_vendor_porg WITH EMPTY KEY,
        info_records             TYPE STANDARD TABLE OF ty_info WITH EMPTY KEY,
        source_list              TYPE STANDARD TABLE OF ty_source WITH EMPTY KEY,
      END OF ty_payload.

    METHODS execute.

  PRIVATE SECTION.
    DATA ms_payload TYPE ty_payload.

    METHODS fetch_data.
    METHODS display_alv.
    METHODS display_json.
    METHODS display_salv_grid IMPORTING !iv_title TYPE string
                              CHANGING  !ct_data  TYPE ANY TABLE.
ENDCLASS.


*---------------------------------------------------------------------*
* CLASS IMPLEMENTATION
*---------------------------------------------------------------------*
CLASS lcl_purchasing_extractor IMPLEMENTATION.

  METHOD execute.
    me->fetch_data( ).

    IF p_json = abap_true.
      me->display_json( ).
    ELSE.
      me->display_alv( ).
    ENDIF.
  ENDMETHOD.

  METHOD fetch_data.
    " Initialize Header Information
    ms_payload-document_type = 'SAP Purchasing As-Is Extraction'.
    ms_payload-system        = sy-sysid.
    ms_payload-client        = sy-mandt.
    ms_payload-generated_by  = sy-uname.
    ms_payload-generated_on  = sy-datum.
    ms_payload-generated_at  = sy-uzeit.

    " 1. Purchasing Organizations
    IF p_porg = abap_true.
      SELECT ekorg, ekotx, bukrs
        FROM t024e
        INTO TABLE @ms_payload-purchasing_organizations
        UP TO @p_max ROWS
        WHERE ekorg IN @s_ekorg.
    ENDIF.

    " 2. Purchasing Groups
    IF p_pgrp = abap_true.
      SELECT ekgrp, eknam
        FROM t024
        INTO TABLE @ms_payload-purchasing_groups
        UP TO @p_max ROWS.
    ENDIF.

    " 3. Purchasing Org / Plant Assignments
    IF p_plant = abap_true.
      SELECT ekorg, werks
        FROM t024w
        INTO TABLE @ms_payload-purchasing_org_plant
        UP TO @p_max ROWS
        WHERE ekorg IN @s_ekorg
          AND werks IN @s_werks.
    ENDIF.

    " 4. Vendor Data
    IF p_vend = abap_true.
      SELECT lifnr, name1, ktokk
        FROM lfa1
        INTO TABLE @ms_payload-vendors
        UP TO @p_max ROWS
        WHERE lifnr IN @s_lifnr.

      IF ms_payload-vendors IS NOT INITIAL.
        SELECT lifnr, ekorg, loevm
          FROM lfm1
          INTO TABLE @ms_payload-vendor_purchasing_org
          FOR ALL ENTRIES IN @ms_payload-vendors
          WHERE lifnr = @ms_payload-vendors-lifnr
            AND ekorg IN @s_ekorg.
      ENDIF.
    ENDIF.

    " 5. Info Records
    IF p_info = abap_true.
      SELECT eina~infnr,
             eina~matnr,
             eina~lifnr,
             eine~ekorg,
             eine~werks,
             eine~esokz,
             eine~netpr,
             eine~waers
        FROM eina
        INNER JOIN eine ON eine~infnr = eina~infnr
        INTO CORRESPONDING FIELDS OF TABLE @ms_payload-info_records
        UP TO @p_max ROWS
        WHERE eina~matnr IN @s_matnr
          AND eina~lifnr IN @s_lifnr
          AND eine~ekorg IN @s_ekorg
          AND eine~werks IN @s_werks.
    ENDIF.

    " 6. Source List
    IF p_src = abap_true.
      SELECT matnr, werks, lifnr, vdatu, bdatu, flifn
        FROM eord
        INTO CORRESPONDING FIELDS OF TABLE @ms_payload-source_list
        UP TO @p_max ROWS
        WHERE matnr IN @s_matnr
          AND werks IN @s_werks
          AND lifnr IN @s_lifnr.
    ENDIF.

    " Populate Summary Metrics
    ms_payload-summary-purchasing_organizations = lines( ms_payload-purchasing_organizations ).
    ms_payload-summary-purchasing_groups        = lines( ms_payload-purchasing_groups ).
    ms_payload-summary-porg_plant_assignments   = lines( ms_payload-purchasing_org_plant ).
    ms_payload-summary-vendors                  = lines( ms_payload-vendors ).
    ms_payload-summary-info_records             = lines( ms_payload-info_records ).
    ms_payload-summary-source_list_entries      = lines( ms_payload-source_list ).
  ENDMETHOD.

  METHOD display_json.
    DATA: lv_json  TYPE string,
          lt_lines TYPE STANDARD TABLE OF char255,
          lv_line  TYPE char255,
          lv_pos   TYPE i,
          lv_len   TYPE i.

    " Dynamic JSON serialization
    lv_json = /ui2/cl_json=>serialize(
                data        = ms_payload
                pretty_name = /ui2/cl_json=>pretty_mode-low_case
              ).

    lv_len = strlen( lv_json ).
    WHILE lv_pos < lv_len.
      lv_line = lv_json+lv_pos(255).
      APPEND lv_line TO lt_lines.
      lv_pos = lv_pos + 255.
    ENDWHILE.

    WRITE: / 'SAP MM Purchasing Data Extractor Payload'.
    ULINE.
    LOOP AT lt_lines INTO lv_line.
      WRITE: / lv_line.
    ENDLOOP.
  ENDMETHOD.

  METHOD display_alv.
    IF ms_payload-purchasing_organizations IS NOT INITIAL.
      me->display_salv_grid( EXPORTING iv_title = 'Purchasing Organizations'
                             CHANGING  ct_data  = ms_payload-purchasing_organizations ).
    ENDIF.

    IF ms_payload-purchasing_groups IS NOT INITIAL.
      me->display_salv_grid( EXPORTING iv_title = 'Purchasing Groups'
                             CHANGING  ct_data  = ms_payload-purchasing_groups ).
    ENDIF.

    IF ms_payload-purchasing_org_plant IS NOT INITIAL.
      me->display_salv_grid( EXPORTING iv_title = 'Purchasing Org Plant Assignments'
                             CHANGING  ct_data  = ms_payload-purchasing_org_plant ).
    ENDIF.

    IF ms_payload-vendors IS NOT INITIAL.
      me->display_salv_grid( EXPORTING iv_title = 'Vendor Master Data'
                             CHANGING  ct_data  = ms_payload-vendors ).
    ENDIF.

    IF ms_payload-info_records IS NOT INITIAL.
      me->display_salv_grid( EXPORTING iv_title = 'Purchasing Info Records'
                             CHANGING  ct_data  = ms_payload-info_records ).
    ENDIF.

    IF ms_payload-source_list IS NOT INITIAL.
      me->display_salv_grid( EXPORTING iv_title = 'Source Lists'
                             CHANGING  ct_data  = ms_payload-source_list ).
    ENDIF.
  ENDMETHOD.

  METHOD display_salv_grid.
    DATA: lo_alv TYPE REF TO cl_salv_table,
          cx_err TYPE REF TO cx_salv_msg.

    TRY.
        cl_salv_table=>factory(
          IMPORTING
            r_salv_table = lo_alv
          CHANGING
            t_table      = ct_data ).

        lo_alv->get_functions( )->set_all( abap_true ).
        lo_alv->get_display_settings( )->set_striped_pattern( abap_true ).
        lo_alv->get_display_settings( )->set_list_header( CONV #( iv_title ) ).
        lo_alv->display( ).
      CATCH cx_salv_msg INTO cx_err.
        MESSAGE cx_err->get_text( ) TYPE 'E'.
    ENDTRY.
  ENDMETHOD.

ENDCLASS.


*---------------------------------------------------------------------*
* INITIALIZATION & START OF SELECTION
*---------------------------------------------------------------------*
INITIALIZATION.
  %_s_ekorg_%_app_%-text = 'Purchasing Org'.
  %_s_werks_%_app_%-text = 'Plant'.
  %_s_lifnr_%_app_%-text = 'Vendor Account'.
  %_s_matnr_%_app_%-text = 'Material Number'.

START-OF-SELECTION.
  NEW lcl_purchasing_extractor( )->execute( ).
