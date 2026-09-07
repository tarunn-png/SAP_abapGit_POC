*&---------------------------------------------------------------------*
*& Report ZMM_PUR_ORDER_REPORT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZMM_PUR_ORDER_REPORT.


TYPE-POOLS: slis.

TABLES:
  ekko,
  ekpo,
  eket,
  ekbe,
  lfa1,
  makt,
  t001w.


*---------------------------------------------------------------------*
* TYPES
*---------------------------------------------------------------------*

TYPES: BEGIN OF ty_ekko,
         ebeln TYPE ekko-ebeln,
         bedat TYPE ekko-bedat,
         lifnr TYPE ekko-lifnr,
         waers TYPE ekko-waers,
         bsart TYPE ekko-bsart,
         ekorg TYPE ekko-ekorg,
         ekgrp TYPE ekko-ekgrp,
       END OF ty_ekko.

TYPES: BEGIN OF ty_ekpo,
         ebeln TYPE ekpo-ebeln,
         ebelp TYPE ekpo-ebelp,
         matnr TYPE ekpo-matnr,
         matkl TYPE ekpo-matkl,
         werks TYPE ekpo-werks,
         menge TYPE ekpo-menge,
         meins TYPE ekpo-meins,
         netwr TYPE ekpo-netwr,
         loekz TYPE ekpo-loekz,
       END OF ty_ekpo.

TYPES: BEGIN OF ty_ekbe,
         ebeln TYPE ekbe-ebeln,
         ebelp TYPE ekbe-ebelp,
         shkzg TYPE ekbe-shkzg,
         menge TYPE ekbe-menge,
       END OF ty_ekbe.

TYPES: BEGIN OF ty_gr,
         ebeln  TYPE ekbe-ebeln,
         ebelp  TYPE ekbe-ebelp,
         gr_qty TYPE ekbe-menge,
       END OF ty_gr.

TYPES: BEGIN OF ty_eket,
         ebeln TYPE eket-ebeln,
         ebelp TYPE eket-ebelp,
         eindt TYPE eket-eindt,
       END OF ty_eket.

TYPES: BEGIN OF ty_due,
         ebeln TYPE eket-ebeln,
         ebelp TYPE eket-ebelp,
         eindt TYPE eket-eindt,
       END OF ty_due.

TYPES: BEGIN OF ty_lfa1,
         lifnr TYPE lfa1-lifnr,
         name1 TYPE lfa1-name1,
       END OF ty_lfa1.

TYPES: BEGIN OF ty_makt,
         matnr TYPE makt-matnr,
         maktx TYPE makt-maktx,
       END OF ty_makt.

TYPES: BEGIN OF ty_t001w,
         werks TYPE t001w-werks,
         name1 TYPE t001w-name1,
       END OF ty_t001w.


*---------------------------------------------------------------------*
* FINAL OUTPUT
*---------------------------------------------------------------------*

TYPES: BEGIN OF ty_output,
         ebeln        TYPE ekpo-ebeln,
         ebelp        TYPE ekpo-ebelp,
         bedat        TYPE ekko-bedat,
         lifnr        TYPE ekko-lifnr,
         name1        TYPE lfa1-name1,
         matnr        TYPE ekpo-matnr,
         maktx        TYPE makt-maktx,
         matkl        TYPE ekpo-matkl,
         werks        TYPE ekpo-werks,
         plant_name   TYPE t001w-name1,
         po_qty       TYPE ekpo-menge,
         gr_qty       TYPE ekpo-menge,
         balance_qty  TYPE ekpo-menge,
         meins        TYPE ekpo-meins,
         eindt        TYPE eket-eindt,
         overdue_days TYPE i,
         status       TYPE char35,
         traffic      TYPE char4,
         netwr        TYPE ekpo-netwr,
         waers        TYPE ekko-waers,
         bsart        TYPE ekko-bsart,
         ekorg        TYPE ekko-ekorg,
         ekgrp        TYPE ekko-ekgrp,
       END OF ty_output.


*---------------------------------------------------------------------*
* INTERNAL TABLES
*---------------------------------------------------------------------*

DATA:
  gt_ekko TYPE STANDARD TABLE OF ty_ekko,
  gs_ekko TYPE ty_ekko.

DATA:
  gt_ekpo TYPE STANDARD TABLE OF ty_ekpo,
  gs_ekpo TYPE ty_ekpo.

DATA:
  gt_ekbe TYPE STANDARD TABLE OF ty_ekbe,
  gs_ekbe TYPE ty_ekbe.

DATA:
  gt_gr TYPE SORTED TABLE OF ty_gr
         WITH UNIQUE KEY ebeln ebelp,
  gs_gr TYPE ty_gr.

DATA:
  gt_eket TYPE STANDARD TABLE OF ty_eket,
  gs_eket TYPE ty_eket.

DATA:
  gt_due TYPE SORTED TABLE OF ty_due
          WITH UNIQUE KEY ebeln ebelp,
  gs_due TYPE ty_due.

DATA:
  gt_lfa1 TYPE SORTED TABLE OF ty_lfa1
           WITH UNIQUE KEY lifnr,
  gs_lfa1 TYPE ty_lfa1.

DATA:
  gt_makt TYPE SORTED TABLE OF ty_makt
           WITH UNIQUE KEY matnr,
  gs_makt TYPE ty_makt.

DATA:
  gt_t001w TYPE SORTED TABLE OF ty_t001w
            WITH UNIQUE KEY werks,
  gs_t001w TYPE ty_t001w.

DATA:
  gt_output TYPE STANDARD TABLE OF ty_output,
  gs_output TYPE ty_output.


*---------------------------------------------------------------------*
* VENDOR OVERDUE AGGREGATION (HISTOGRAM)
*---------------------------------------------------------------------*

TYPES: BEGIN OF ty_vendor,
         lifnr        TYPE ekko-lifnr,
         name1        TYPE lfa1-name1,
         total_days   TYPE i,
         max_days     TYPE i,
         items        TYPE i,
         balance_qty  TYPE ekpo-menge,
         oldest_eindt TYPE eket-eindt,
         status       TYPE char35,
       END OF ty_vendor.

DATA:
  gt_vendor TYPE STANDARD TABLE OF ty_vendor,
  gs_vendor TYPE ty_vendor.

DATA:
  gv_html TYPE string.


*---------------------------------------------------------------------*
* ALV DATA
*---------------------------------------------------------------------*

DATA:
  gt_fieldcat TYPE slis_t_fieldcat_alv,
  gs_fieldcat TYPE slis_fieldcat_alv.

DATA:
  gt_sort TYPE slis_t_sortinfo_alv,
  gs_sort TYPE slis_sortinfo_alv.

DATA:
  gt_events TYPE slis_t_event,
  gs_event  TYPE slis_alv_event.

DATA:
  gs_layout TYPE slis_layout_alv.

DATA:
  gv_repid TYPE sy-repid.


*---------------------------------------------------------------------*
* SUMMARY
*---------------------------------------------------------------------*

DATA:
  gv_total         TYPE i,
  gv_complete      TYPE i,
  gv_partial       TYPE i,
  gv_not_delivered TYPE i,
  gv_overdue       TYPE i.

DATA:
  gv_total_c         TYPE char20,
  gv_complete_c      TYPE char20,
  gv_partial_c       TYPE char20,
  gv_not_delivered_c TYPE char20,
  gv_overdue_c       TYPE char20.


*---------------------------------------------------------------------*
* ICONS
*---------------------------------------------------------------------*

CONSTANTS:
  c_green  TYPE char4 VALUE '@08@',
  c_yellow TYPE char4 VALUE '@09@',
  c_red    TYPE char4 VALUE '@0A@'.


*---------------------------------------------------------------------*
* SELECTION SCREEN
*---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE text-001.

SELECT-OPTIONS:
  s_ebeln FOR ekko-ebeln,
  s_bedat FOR ekko-bedat,
  s_lifnr FOR ekko-lifnr,
  s_matnr FOR ekpo-matnr,
  s_matkl FOR ekpo-matkl,
  s_werks FOR ekpo-werks.

SELECTION-SCREEN END OF BLOCK b1.


SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME TITLE text-002.

SELECT-OPTIONS:
  s_eindt FOR eket-eindt.

SELECTION-SCREEN END OF BLOCK b2.


SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME TITLE text-003.

PARAMETERS:
  p_all  RADIOBUTTON GROUP r1 DEFAULT 'X',
  p_open RADIOBUTTON GROUP r1,
  p_comp RADIOBUTTON GROUP r1,
  p_part RADIOBUTTON GROUP r1,
  p_nogr RADIOBUTTON GROUP r1,
  p_over RADIOBUTTON GROUP r1.

SELECTION-SCREEN END OF BLOCK b3.


SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME TITLE text-004.

PARAMETERS:
  p_sort AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK b4.


SELECTION-SCREEN BEGIN OF BLOCK b5 WITH FRAME TITLE text-005.

PARAMETERS:
  p_chart AS CHECKBOX DEFAULT 'X',
  p_grid  AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK b5.


*---------------------------------------------------------------------*
* START
*---------------------------------------------------------------------*

START-OF-SELECTION.

  PERFORM get_data.

  IF gt_output[] IS INITIAL.
    MESSAGE 'No Purchase Orders found for the selection' TYPE 'I'.
    EXIT.
  ENDIF.

  PERFORM calculate_summary.

  IF p_chart = 'X'.
    PERFORM show_vendor_dashboard.
  ENDIF.

  IF p_grid = 'X'.
    PERFORM build_fieldcatalog.
    PERFORM build_sort.
    PERFORM build_events.
    PERFORM display_alv.
  ENDIF.


*---------------------------------------------------------------------*
* GET DATA
*---------------------------------------------------------------------*

FORM get_data.

*---------------------------------------------------------------------*
* 1. GET PO HEADER
*---------------------------------------------------------------------*

  SELECT ebeln
         bedat
         lifnr
         waers
         bsart
         ekorg
         ekgrp
    INTO TABLE gt_ekko
    FROM ekko
    WHERE ebeln IN s_ebeln
      AND bedat IN s_bedat
      AND lifnr IN s_lifnr.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.


*---------------------------------------------------------------------*
* 2. GET PO ITEMS
*---------------------------------------------------------------------*

  SELECT ebeln
         ebelp
         matnr
         matkl
         werks
         menge
         meins
         netwr
         loekz
    INTO TABLE gt_ekpo
    FROM ekpo
    FOR ALL ENTRIES IN gt_ekko
    WHERE ebeln = gt_ekko-ebeln
      AND matnr IN s_matnr
      AND matkl IN s_matkl
      AND werks IN s_werks.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.


*---------------------------------------------------------------------*
* 3. REMOVE DELETED ITEMS
*---------------------------------------------------------------------*

  DELETE gt_ekpo WHERE loekz IS NOT INITIAL.

  IF gt_ekpo[] IS INITIAL.
    RETURN.
  ENDIF.


*---------------------------------------------------------------------*
* 4. GET PO HISTORY - EKBE
*---------------------------------------------------------------------*

  SELECT ebeln
         ebelp
         shkzg
         menge
    INTO TABLE gt_ekbe
    FROM ekbe
    FOR ALL ENTRIES IN gt_ekpo
    WHERE ebeln = gt_ekpo-ebeln
      AND ebelp = gt_ekpo-ebelp
      AND vgabe = '1'.

*---------------------------------------------------------------------*
* 5. AGGREGATE GR QUANTITY ONCE
*---------------------------------------------------------------------*

  IF gt_ekbe[] IS NOT INITIAL.

    SORT gt_ekbe BY ebeln ebelp.

    CLEAR gs_gr.

    LOOP AT gt_ekbe INTO gs_ekbe.

      AT NEW ebelp.

        CLEAR gs_gr.

        gs_gr-ebeln = gs_ekbe-ebeln.
        gs_gr-ebelp = gs_ekbe-ebelp.
        gs_gr-gr_qty = 0.

      ENDAT.


      IF gs_ekbe-shkzg = 'S'.

        gs_gr-gr_qty = gs_gr-gr_qty + gs_ekbe-menge.

      ELSEIF gs_ekbe-shkzg = 'H'.

        gs_gr-gr_qty = gs_gr-gr_qty - gs_ekbe-menge.

      ENDIF.


      AT END OF ebelp.

        IF gs_gr-gr_qty < 0.
          gs_gr-gr_qty = 0.
        ENDIF.

        INSERT gs_gr INTO TABLE gt_gr.

      ENDAT.

    ENDLOOP.

  ENDIF.


*---------------------------------------------------------------------*
* 6. GET DELIVERY DATES
*---------------------------------------------------------------------*

  SELECT ebeln
         ebelp
         eindt
    INTO TABLE gt_eket
    FROM eket
    FOR ALL ENTRIES IN gt_ekpo
    WHERE ebeln = gt_ekpo-ebeln
      AND ebelp = gt_ekpo-ebelp.

*---------------------------------------------------------------------*
* 7. DETERMINE EARLIEST DELIVERY DATE ONCE
*---------------------------------------------------------------------*

  IF gt_eket[] IS NOT INITIAL.

    SORT gt_eket BY ebeln ebelp eindt.

    CLEAR gs_due.

    LOOP AT gt_eket INTO gs_eket.

      READ TABLE gt_due
        WITH TABLE KEY
          ebeln = gs_eket-ebeln
          ebelp = gs_eket-ebelp
        TRANSPORTING NO FIELDS.

      IF sy-subrc <> 0.

        CLEAR gs_due.

        gs_due-ebeln = gs_eket-ebeln.
        gs_due-ebelp = gs_eket-ebelp.
        gs_due-eindt = gs_eket-eindt.

        INSERT gs_due INTO TABLE gt_due.

      ENDIF.

    ENDLOOP.

  ENDIF.


*---------------------------------------------------------------------*
* 8. GET VENDOR MASTER DATA
*---------------------------------------------------------------------*

  SELECT lifnr
         name1
    INTO TABLE gt_lfa1
    FROM lfa1
    FOR ALL ENTRIES IN gt_ekko
    WHERE lifnr = gt_ekko-lifnr.


*---------------------------------------------------------------------*
* 9. GET MATERIAL DESCRIPTION
*---------------------------------------------------------------------*

  SELECT matnr
         maktx
    INTO TABLE gt_makt
    FROM makt
    FOR ALL ENTRIES IN gt_ekpo
    WHERE matnr = gt_ekpo-matnr
      AND spras = sy-langu.


*---------------------------------------------------------------------*
* 10. GET PLANT DESCRIPTION
*---------------------------------------------------------------------*

  SELECT werks
         name1
    INTO TABLE gt_t001w
    FROM t001w
    FOR ALL ENTRIES IN gt_ekpo
    WHERE werks = gt_ekpo-werks.


*---------------------------------------------------------------------*
* 11. BUILD FINAL OUTPUT
*---------------------------------------------------------------------*

  LOOP AT gt_ekpo INTO gs_ekpo.

    CLEAR gs_output.


*---------------------------------------------------------------------*
* PO HEADER
*---------------------------------------------------------------------*

    gs_output-ebeln = gs_ekpo-ebeln.
    gs_output-ebelp = gs_ekpo-ebelp.
    gs_output-matnr = gs_ekpo-matnr.
    gs_output-matkl = gs_ekpo-matkl.
    gs_output-werks = gs_ekpo-werks.
    gs_output-po_qty = gs_ekpo-menge.
    gs_output-meins = gs_ekpo-meins.
    gs_output-netwr = gs_ekpo-netwr.


    READ TABLE gt_ekko INTO gs_ekko
      WITH KEY ebeln = gs_ekpo-ebeln
      BINARY SEARCH.

    IF sy-subrc = 0.

      gs_output-bedat = gs_ekko-bedat.
      gs_output-lifnr = gs_ekko-lifnr.
      gs_output-waers = gs_ekko-waers.
      gs_output-bsart = gs_ekko-bsart.
      gs_output-ekorg = gs_ekko-ekorg.
      gs_output-ekgrp = gs_ekko-ekgrp.

    ENDIF.


*---------------------------------------------------------------------*
* VENDOR
*---------------------------------------------------------------------*

    READ TABLE gt_lfa1 INTO gs_lfa1
      WITH TABLE KEY lifnr = gs_output-lifnr.

    IF sy-subrc = 0.
      gs_output-name1 = gs_lfa1-name1.
    ENDIF.


*---------------------------------------------------------------------*
* MATERIAL DESCRIPTION
*---------------------------------------------------------------------*

    READ TABLE gt_makt INTO gs_makt
      WITH TABLE KEY matnr = gs_output-matnr.

    IF sy-subrc = 0.
      gs_output-maktx = gs_makt-maktx.
    ENDIF.


*---------------------------------------------------------------------*
* PLANT
*---------------------------------------------------------------------*

    READ TABLE gt_t001w INTO gs_t001w
      WITH TABLE KEY werks = gs_output-werks.

    IF sy-subrc = 0.
      gs_output-plant_name = gs_t001w-name1.
    ENDIF.


*---------------------------------------------------------------------*
* GR QUANTITY
*---------------------------------------------------------------------*

    CLEAR gs_gr.

    READ TABLE gt_gr INTO gs_gr
      WITH TABLE KEY
        ebeln = gs_output-ebeln
        ebelp = gs_output-ebelp.

    IF sy-subrc = 0.
      gs_output-gr_qty = gs_gr-gr_qty.
    ELSE.
      gs_output-gr_qty = 0.
    ENDIF.


*---------------------------------------------------------------------*
* BALANCE
*---------------------------------------------------------------------*

    gs_output-balance_qty =
      gs_output-po_qty - gs_output-gr_qty.

    IF gs_output-balance_qty < 0.
      gs_output-balance_qty = 0.
    ENDIF.


*---------------------------------------------------------------------*
* DELIVERY DATE
*---------------------------------------------------------------------*

    CLEAR gs_due.

    READ TABLE gt_due INTO gs_due
      WITH TABLE KEY
        ebeln = gs_output-ebeln
        ebelp = gs_output-ebelp.

    IF sy-subrc = 0.
      gs_output-eindt = gs_due-eindt.
    ENDIF.


*---------------------------------------------------------------------*
* DELIVERY DATE SELECTION
*---------------------------------------------------------------------*

    IF s_eindt[] IS NOT INITIAL.

      IF gs_output-eindt NOT IN s_eindt.
        CONTINUE.
      ENDIF.

    ENDIF.


*---------------------------------------------------------------------*
* DETERMINE STATUS
*---------------------------------------------------------------------*

    PERFORM determine_status.


*---------------------------------------------------------------------*
* STATUS FILTER
*---------------------------------------------------------------------*

    PERFORM apply_status_filter.

    IF sy-subrc <> 0.
      CONTINUE.
    ENDIF.


*---------------------------------------------------------------------*
* APPEND
*---------------------------------------------------------------------*

    APPEND gs_output TO gt_output.

  ENDLOOP.

ENDFORM.


*---------------------------------------------------------------------*
* DETERMINE STATUS
*---------------------------------------------------------------------*

FORM determine_status.

  CLEAR gs_output-overdue_days.


*---------------------------------------------------------------------*
* COMPLETELY DELIVERED
*---------------------------------------------------------------------*

  IF gs_output-gr_qty >= gs_output-po_qty.

    gs_output-status = 'COMPLETELY DELIVERED'.
    gs_output-traffic = c_green.


*---------------------------------------------------------------------*
* PARTIALLY DELIVERED
*---------------------------------------------------------------------*

  ELSEIF gs_output-gr_qty > 0.

    IF gs_output-eindt IS NOT INITIAL
       AND gs_output-eindt < sy-datum.

      gs_output-status = 'PARTIAL / OVERDUE'.
      gs_output-traffic = c_red.

      gs_output-overdue_days =
        sy-datum - gs_output-eindt.

    ELSE.

      gs_output-status = 'PARTIALLY DELIVERED'.
      gs_output-traffic = c_yellow.

    ENDIF.


*---------------------------------------------------------------------*
* NOT DELIVERED
*---------------------------------------------------------------------*

  ELSE.

    IF gs_output-eindt IS NOT INITIAL
       AND gs_output-eindt < sy-datum.

      gs_output-status = 'NOT DELIVERED / OVERDUE'.
      gs_output-traffic = c_red.

      gs_output-overdue_days =
        sy-datum - gs_output-eindt.

    ELSE.

      gs_output-status = 'NOT DELIVERED'.
      gs_output-traffic = c_yellow.

    ENDIF.

  ENDIF.

ENDFORM.


*---------------------------------------------------------------------*
* STATUS FILTER
*---------------------------------------------------------------------*

FORM apply_status_filter.

  sy-subrc = 0.


  IF p_all = 'X'.
    RETURN.
  ENDIF.


*---------------------------------------------------------------------*
* OPEN
*---------------------------------------------------------------------*

  IF p_open = 'X'.

    IF gs_output-balance_qty <= 0.
      sy-subrc = 4.
      RETURN.
    ENDIF.

  ENDIF.


*---------------------------------------------------------------------*
* COMPLETE
*---------------------------------------------------------------------*

  IF p_comp = 'X'.

    IF gs_output-status <> 'COMPLETELY DELIVERED'.
      sy-subrc = 4.
      RETURN.
    ENDIF.

  ENDIF.


*---------------------------------------------------------------------*
* PARTIAL
*---------------------------------------------------------------------*

  IF p_part = 'X'.

    IF gs_output-gr_qty <= 0
       OR gs_output-balance_qty <= 0.

      sy-subrc = 4.
      RETURN.

    ENDIF.

  ENDIF.


*---------------------------------------------------------------------*
* NOT DELIVERED
*---------------------------------------------------------------------*

  IF p_nogr = 'X'.

    IF gs_output-gr_qty <> 0.
      sy-subrc = 4.
      RETURN.
    ENDIF.

  ENDIF.


*---------------------------------------------------------------------*
* OVERDUE
*---------------------------------------------------------------------*

  IF p_over = 'X'.

    IF gs_output-balance_qty <= 0
       OR gs_output-eindt IS INITIAL
       OR gs_output-eindt >= sy-datum.

      sy-subrc = 4.
      RETURN.

    ENDIF.

  ENDIF.

ENDFORM.


*---------------------------------------------------------------------*
* CALCULATE SUMMARY
*---------------------------------------------------------------------*

FORM calculate_summary.

  DATA:
    ls_summary TYPE ty_output.

  CLEAR:
    gv_total,
    gv_complete,
    gv_partial,
    gv_not_delivered,
    gv_overdue.

  LOOP AT gt_output INTO ls_summary.

    gv_total = gv_total + 1.


    IF ls_summary-status = 'COMPLETELY DELIVERED'.

      gv_complete = gv_complete + 1.

    ELSEIF ls_summary-status = 'PARTIALLY DELIVERED'
        OR ls_summary-status = 'PARTIAL / OVERDUE'.

      gv_partial = gv_partial + 1.

    ELSEIF ls_summary-status = 'NOT DELIVERED'
        OR ls_summary-status = 'NOT DELIVERED / OVERDUE'.

      gv_not_delivered = gv_not_delivered + 1.

    ENDIF.


    IF ls_summary-balance_qty > 0
       AND ls_summary-eindt IS NOT INITIAL
       AND ls_summary-eindt < sy-datum.

      gv_overdue = gv_overdue + 1.

    ENDIF.

  ENDLOOP.

ENDFORM.


*---------------------------------------------------------------------*
* BUILD FIELD CATALOG
*---------------------------------------------------------------------*

FORM build_fieldcatalog.

  CLEAR gt_fieldcat[].


  PERFORM add_field USING:
    'TRAFFIC'      'Traffic'          6  '',
    'EBELN'        'PO Number'       12  '',
    'EBELP'        'Item'             6  '',
    'BEDAT'        'PO Date'         10  '',
    'LIFNR'        'Vendor'          10  '',
    'NAME1'        'Vendor Name'     25  '',
    'MATNR'        'Material'        18  '',
    'MAKTX'        'Material Desc.'  30  '',
    'MATKL'        'Mat. Group'       9  '',
    'WERKS'        'Plant'            6  '',
    'PLANT_NAME'   'Plant Name'      20  '',
    'PO_QTY'       'PO Qty'           12  '',
    'GR_QTY'       'GR Qty'           12  '',
    'BALANCE_QTY'  'Balance Qty'      12  '',
    'MEINS'        'UoM'               5  '',
    'EINDT'        'Delivery Date'    12  '',
    'OVERDUE_DAYS' 'Overdue Days'     12  '',
    'STATUS'       'Delivery Status'  25  '',
    'NETWR'        'Net Value'        15  '',
    'WAERS'        'Currency'          8  '',
    'BSART'        'PO Type'           8  '',
    'EKORG'        'Purch. Org.'       10 '',
    'EKGRP'        'Purch. Group'       10 ''.


*---------------------------------------------------------------------*
* SPECIAL SETTINGS
*---------------------------------------------------------------------*

  READ TABLE gt_fieldcat INTO gs_fieldcat
    WITH KEY fieldname = 'TRAFFIC'.

  IF sy-subrc = 0.

    gs_fieldcat-icon = 'X'.

    MODIFY gt_fieldcat FROM gs_fieldcat INDEX sy-tabix.

  ENDIF.


*---------------------------------------------------------------------*
* QUANTITY SETTINGS
*---------------------------------------------------------------------*

  PERFORM set_quantity_field USING 'PO_QTY'.
  PERFORM set_quantity_field USING 'GR_QTY'.
  PERFORM set_quantity_field USING 'BALANCE_QTY'.


*---------------------------------------------------------------------*
* NET VALUE
*---------------------------------------------------------------------*

  READ TABLE gt_fieldcat INTO gs_fieldcat
    WITH KEY fieldname = 'NETWR'.

  IF sy-subrc = 0.

    gs_fieldcat-do_sum = 'X'.
    gs_fieldcat-cfieldname = 'WAERS'.

    MODIFY gt_fieldcat FROM gs_fieldcat INDEX sy-tabix.

  ENDIF.


*---------------------------------------------------------------------*
* KEY FIELD
*---------------------------------------------------------------------*

  READ TABLE gt_fieldcat INTO gs_fieldcat
    WITH KEY fieldname = 'EBELN'.

  IF sy-subrc = 0.

    gs_fieldcat-key = 'X'.

    MODIFY gt_fieldcat FROM gs_fieldcat INDEX sy-tabix.

  ENDIF.

ENDFORM.


*---------------------------------------------------------------------*
* ADD FIELD
*---------------------------------------------------------------------*

FORM add_field
  USING
    p_fieldname TYPE slis_fieldname
    p_text      TYPE char40
    p_length    TYPE i
    p_no_out    TYPE char1.

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = p_fieldname.
  gs_fieldcat-seltext_m = p_text.
  gs_fieldcat-outputlen = p_length.
  gs_fieldcat-no_out    = p_no_out.

  APPEND gs_fieldcat TO gt_fieldcat.

ENDFORM.


*---------------------------------------------------------------------*
* QUANTITY FIELD
*---------------------------------------------------------------------*

FORM set_quantity_field
  USING p_fieldname TYPE slis_fieldname.

  READ TABLE gt_fieldcat INTO gs_fieldcat
    WITH KEY fieldname = p_fieldname.

  IF sy-subrc = 0.

    gs_fieldcat-qfieldname = 'MEINS'.

    MODIFY gt_fieldcat FROM gs_fieldcat INDEX sy-tabix.

  ENDIF.

ENDFORM.


*---------------------------------------------------------------------*
* BUILD SORT
*---------------------------------------------------------------------*

FORM build_sort.

  CLEAR gt_sort[].

  IF p_sort <> 'X'.
    RETURN.
  ENDIF.


  CLEAR gs_sort.

  gs_sort-fieldname = 'WERKS'.
  gs_sort-up = 'X'.
  gs_sort-subtot = 'X'.

  APPEND gs_sort TO gt_sort.


  CLEAR gs_sort.

  gs_sort-fieldname = 'LIFNR'.
  gs_sort-up = 'X'.

  APPEND gs_sort TO gt_sort.


  CLEAR gs_sort.

  gs_sort-fieldname = 'EINDT'.
  gs_sort-up = 'X'.

  APPEND gs_sort TO gt_sort.

ENDFORM.


*---------------------------------------------------------------------*
* BUILD EVENTS
*---------------------------------------------------------------------*

FORM build_events.

  CALL FUNCTION 'REUSE_ALV_EVENTS_GET'
    EXPORTING
      i_list_type = 0
    IMPORTING
      et_events   = gt_events.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.


  READ TABLE gt_events INTO gs_event
    WITH KEY name = 'TOP_OF_PAGE'.

  IF sy-subrc = 0.

    gs_event-form = 'TOP_OF_PAGE'.

    MODIFY gt_events FROM gs_event INDEX sy-tabix.

  ENDIF.


  READ TABLE gt_events INTO gs_event
    WITH KEY name = 'USER_COMMAND'.

  IF sy-subrc = 0.

    gs_event-form = 'USER_COMMAND'.

    MODIFY gt_events FROM gs_event INDEX sy-tabix.

  ENDIF.

ENDFORM.


*---------------------------------------------------------------------*
* DISPLAY ALV
*---------------------------------------------------------------------*

FORM display_alv.

  gv_repid = sy-repid.

  CLEAR gs_layout.

  gs_layout-zebra             = 'X'.
  gs_layout-colwidth_optimize = 'X'.
  gs_layout-info_fieldname    = 'TRAFFIC'.


  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program      = gv_repid
      i_callback_user_command = 'USER_COMMAND'
      is_layout               = gs_layout
      it_fieldcat             = gt_fieldcat
      it_sort                 = gt_sort
      it_events               = gt_events
      i_save                  = 'A'
    TABLES
      t_outtab                = gt_output
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.

  IF sy-subrc <> 0.

    MESSAGE 'Error while displaying ALV' TYPE 'I'.

  ENDIF.

ENDFORM.


*---------------------------------------------------------------------*
* TOP OF PAGE
*---------------------------------------------------------------------*

FORM top_of_page.

  DATA:
    lt_header TYPE slis_t_listheader,
    ls_header TYPE slis_listheader.

  DATA:
    lv_text TYPE char100.

  CLEAR lt_header[].


*---------------------------------------------------------------------*
* TITLE
*---------------------------------------------------------------------*

  CLEAR ls_header.

  ls_header-typ  = 'H'.
  ls_header-info = 'Purchase Order Delivery Status'.

  APPEND ls_header TO lt_header.


*---------------------------------------------------------------------*
* TOTAL
*---------------------------------------------------------------------*

  WRITE gv_total TO gv_total_c.
  WRITE gv_complete TO gv_complete_c.
  WRITE gv_partial TO gv_partial_c.
  WRITE gv_not_delivered TO gv_not_delivered_c.
  WRITE gv_overdue TO gv_overdue_c.


  CLEAR ls_header.

  ls_header-typ = 'S'.

  CONCATENATE
    'Total POs:'
    gv_total_c
    INTO lv_text
    SEPARATED BY space.

  ls_header-info = lv_text.

  APPEND ls_header TO lt_header.


*---------------------------------------------------------------------*
* COMPLETE
*---------------------------------------------------------------------*

  CLEAR ls_header.

  ls_header-typ = 'S'.

  CONCATENATE
    'Completely Delivered:'
    gv_complete_c
    INTO lv_text
    SEPARATED BY space.

  ls_header-info = lv_text.

  APPEND ls_header TO lt_header.


*---------------------------------------------------------------------*
* PARTIAL
*---------------------------------------------------------------------*

  CLEAR ls_header.

  ls_header-typ = 'S'.

  CONCATENATE
    'Partially Delivered:'
    gv_partial_c
    INTO lv_text
    SEPARATED BY space.

  ls_header-info = lv_text.

  APPEND ls_header TO lt_header.


*---------------------------------------------------------------------*
* NOT DELIVERED
*---------------------------------------------------------------------*

  CLEAR ls_header.

  ls_header-typ = 'S'.

  CONCATENATE
    'Not Delivered:'
    gv_not_delivered_c
    INTO lv_text
    SEPARATED BY space.

  ls_header-info = lv_text.

  APPEND ls_header TO lt_header.


*---------------------------------------------------------------------*
* OVERDUE
*---------------------------------------------------------------------*

  CLEAR ls_header.

  ls_header-typ = 'S'.

  CONCATENATE
    'Overdue:'
    gv_overdue_c
    INTO lv_text
    SEPARATED BY space.

  ls_header-info = lv_text.

  APPEND ls_header TO lt_header.


  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header.

ENDFORM.


*---------------------------------------------------------------------*
* USER COMMAND
*---------------------------------------------------------------------*

FORM user_command
  USING
    p_ucomm     LIKE sy-ucomm
    p_selfield  TYPE slis_selfield.

  DATA:
    lv_ebeln TYPE ekpo-ebeln.

  IF p_ucomm = '&IC1'.

    IF p_selfield-fieldname = 'EBELN'.

      READ TABLE gt_output INTO gs_output
        INDEX p_selfield-tabindex.

      IF sy-subrc = 0.

        lv_ebeln = gs_output-ebeln.

        SET PARAMETER ID 'BES' FIELD lv_ebeln.

        CALL TRANSACTION 'ME23N'
          AND SKIP FIRST SCREEN.

      ENDIF.

    ENDIF.

  ENDIF.

ENDFORM.


*---------------------------------------------------------------------*
* SHOW VENDOR DASHBOARD (TOP 10 OVERDUE VENDORS)
*---------------------------------------------------------------------*

FORM show_vendor_dashboard.

  PERFORM collect_vendor_overdue.

  IF gt_vendor[] IS INITIAL.

    MESSAGE 'No open overdue PO items found for the chart' TYPE 'S'.
    RETURN.

  ENDIF.

  PERFORM build_dashboard_html.

  CALL METHOD cl_abap_browser=>show_html
    EXPORTING
      title       = 'Open PO Dashboard - Top 10 Overdue Vendors'
      html_string = gv_html
      size        = cl_abap_browser=>large
      modal       = 'X'.

ENDFORM.


*---------------------------------------------------------------------*
* COLLECT / AGGREGATE OVERDUE DAYS PER VENDOR
*---------------------------------------------------------------------*

FORM collect_vendor_overdue.

  DATA:
    ls_out   TYPE ty_output,
    lv_index TYPE sy-tabix,
    lv_lines TYPE i.

  CLEAR gt_vendor[].


  LOOP AT gt_output INTO ls_out.

*---------------------------------------------------------------------*
* ONLY OPEN OVERDUE ITEMS
*---------------------------------------------------------------------*

    IF ls_out-balance_qty <= 0.
      CONTINUE.
    ENDIF.

    IF ls_out-eindt IS INITIAL
       OR ls_out-eindt >= sy-datum.
      CONTINUE.
    ENDIF.

    IF ls_out-overdue_days <= 0.
      CONTINUE.
    ENDIF.


*---------------------------------------------------------------------*
* AGGREGATE BY VENDOR
*---------------------------------------------------------------------*

    CLEAR gs_vendor.

    READ TABLE gt_vendor INTO gs_vendor
      WITH KEY lifnr = ls_out-lifnr.

    IF sy-subrc = 0.

      lv_index = sy-tabix.

      gs_vendor-total_days  = gs_vendor-total_days + ls_out-overdue_days.
      gs_vendor-items       = gs_vendor-items + 1.
      gs_vendor-balance_qty = gs_vendor-balance_qty + ls_out-balance_qty.

      IF ls_out-overdue_days > gs_vendor-max_days.

        gs_vendor-max_days = ls_out-overdue_days.
        gs_vendor-status   = ls_out-status.

      ENDIF.

      IF ls_out-eindt < gs_vendor-oldest_eindt.
        gs_vendor-oldest_eindt = ls_out-eindt.
      ENDIF.

      MODIFY gt_vendor FROM gs_vendor INDEX lv_index.

    ELSE.

      CLEAR gs_vendor.

      gs_vendor-lifnr        = ls_out-lifnr.
      gs_vendor-name1        = ls_out-name1.
      gs_vendor-total_days   = ls_out-overdue_days.
      gs_vendor-max_days     = ls_out-overdue_days.
      gs_vendor-items        = 1.
      gs_vendor-balance_qty  = ls_out-balance_qty.
      gs_vendor-oldest_eindt = ls_out-eindt.
      gs_vendor-status       = ls_out-status.

      IF gs_vendor-name1 IS INITIAL.
        gs_vendor-name1 = gs_vendor-lifnr.
      ENDIF.

      APPEND gs_vendor TO gt_vendor.

    ENDIF.

  ENDLOOP.


*---------------------------------------------------------------------*
* SORT DESCENDING AND KEEP TOP 10
*---------------------------------------------------------------------*

  SORT gt_vendor BY total_days DESCENDING max_days DESCENDING name1 ASCENDING.

  DESCRIBE TABLE gt_vendor LINES lv_lines.

  IF lv_lines > 10.

    lv_index = 11.

    DELETE gt_vendor FROM lv_index TO lv_lines.

  ENDIF.

ENDFORM.


*---------------------------------------------------------------------*
* BUILD DASHBOARD HTML
*---------------------------------------------------------------------*

FORM build_dashboard_html.

  DATA:
    lv_max      TYPE i,
    lv_sum      TYPE i,
    lv_avg      TYPE i,
    lv_rank     TYPE i,
    lv_pct      TYPE i,
    lv_tick     TYPE i,
    lv_str      TYPE string,
    lv_str2     TYPE string,
    lv_name     TYPE string,
    lv_tip      TYPE string,
    lv_fill     TYPE string,
    lv_glow     TYPE string,
    lv_date     TYPE string,
    lv_today    TYPE string,
    lv_qty      TYPE string,
    lv_worst    TYPE string,
    lv_lines    TYPE i,
    lv_qty_char TYPE char20.

  CLEAR gv_html.


*---------------------------------------------------------------------*
* HEADER FIGURES
*---------------------------------------------------------------------*

  CLEAR: lv_max, lv_sum.

  LOOP AT gt_vendor INTO gs_vendor.

    lv_sum = lv_sum + gs_vendor-total_days.

    IF gs_vendor-total_days > lv_max.

      lv_max = gs_vendor-total_days.

      PERFORM esc_html USING gs_vendor-name1 CHANGING lv_worst.

    ENDIF.

  ENDLOOP.

  IF lv_max <= 0.
    lv_max = 1.
  ENDIF.

  DESCRIBE TABLE gt_vendor LINES lv_lines.

  IF lv_lines > 0.
    lv_avg = lv_sum / lv_lines.
  ENDIF.

  PERFORM date_to_str USING sy-datum CHANGING lv_today.


*---------------------------------------------------------------------*
* DOCUMENT HEAD AND STYLES
*---------------------------------------------------------------------*

  PERFORM add_html USING '<html><head>'.
  PERFORM add_html USING '<meta http-equiv="X-UA-Compatible" content="IE=edge">'.
  PERFORM add_html USING '<title>Open PO Dashboard</title>'.
  PERFORM add_html USING '<style type="text/css">'.

  PERFORM add_html USING 'body{margin:0;background:#0d1524;color:#e7eefb;'.
  PERFORM add_html USING 'font-family:Segoe UI,Tahoma,Arial,sans-serif;font-size:13px;}'.
  PERFORM add_html USING '.wrap{padding:18px 22px 26px 22px;}'.
  PERFORM add_html USING '.hdr{border-bottom:1px solid #1e2b45;padding-bottom:12px;}'.
  PERFORM add_html USING '.h1{font-size:21px;font-weight:700;color:#ffffff;}'.
  PERFORM add_html USING '.sub{font-size:11px;color:#8598b8;margin-top:5px;}'.
  PERFORM add_html USING '.kpi{width:100%;border-collapse:separate;border-spacing:9px 0;'.
  PERFORM add_html USING 'margin:16px 0 16px -9px;}'.
  PERFORM add_html USING '.card{background:#152138;border:1px solid #223a5c;'.
  PERFORM add_html USING 'border-radius:10px;padding:11px 14px;}'.
  PERFORM add_html USING '.klab{font-size:10px;color:#8598b8;letter-spacing:.08em;}'.
  PERFORM add_html USING '.kval{font-size:19px;font-weight:700;color:#ffffff;margin-top:5px;}'.
  PERFORM add_html USING '.kfoot{font-size:10px;color:#6f83a3;margin-top:3px;}'.
  PERFORM add_html USING '.panel{background:#101b2e;border:1px solid #223a5c;'.
  PERFORM add_html USING 'border-radius:12px;padding:16px 20px 20px 20px;}'.
  PERFORM add_html USING '.ptit{font-size:15px;font-weight:600;color:#ffffff;}'.
  PERFORM add_html USING '.pnote{font-size:11px;color:#8598b8;margin:4px 0 16px 0;}'.
  PERFORM add_html USING '.chart{width:100%;border-collapse:collapse;}'.
  PERFORM add_html USING '.chart td{padding:6px 0;vertical-align:middle;}'.
  PERFORM add_html USING '.row:hover{background:#16233c;}'.
  PERFORM add_html USING '.rk{width:36px;}'.
  PERFORM add_html USING '.badge{display:inline-block;width:24px;height:24px;'.
  PERFORM add_html USING 'line-height:24px;text-align:center;border-radius:7px;'.
  PERFORM add_html USING 'background:#22314f;color:#d3e2ff;font-size:11px;font-weight:700;}'.
  PERFORM add_html USING '.top3{background:#3a1d2c;color:#ffb3c4;}'.
  PERFORM add_html USING '.vend{width:230px;padding-right:14px;color:#e2ebfa;font-size:12px;}'.
  PERFORM add_html USING '.vsub{font-size:10px;color:#7e92b2;margin-top:2px;}'.
  PERFORM add_html USING '.track{background:#18243c;border-radius:7px;height:22px;}'.
  PERFORM add_html USING '.fill{height:22px;border-radius:7px;}'.
  PERFORM add_html USING '.val{width:118px;text-align:right;padding-left:14px;'.
  PERFORM add_html USING 'font-size:14px;font-weight:700;color:#ffffff;}'.
  PERFORM add_html USING '.unit{font-size:10px;font-weight:400;color:#8598b8;}'.
  PERFORM add_html USING '.axis{width:100%;border-collapse:collapse;}'.
  PERFORM add_html USING '.axis td{font-size:10px;color:#6f83a3;padding-top:6px;'.
  PERFORM add_html USING 'border-top:1px solid #1e2b45;}'.
  PERFORM add_html USING '.axr{text-align:right;}'.
  PERFORM add_html USING '.foot{font-size:10px;color:#6f83a3;margin-top:14px;}'.

  PERFORM add_html USING '</style></head><body><div class="wrap">'.


*---------------------------------------------------------------------*
* TITLE
*---------------------------------------------------------------------*

  PERFORM add_html USING '<div class="hdr">'.
  PERFORM add_html USING '<div class="h1">Open PO Overdue Dashboard</div>'.

  CONCATENATE
    '<div class="sub">Top 10 vendors by total overdue days &middot;'
    ' open items only (balance qty &gt; 0, delivery date &lt; '
    lv_today
    ')</div></div>'
    INTO lv_str.

  PERFORM add_html USING lv_str.


*---------------------------------------------------------------------*
* KPI CARDS
*---------------------------------------------------------------------*

  PERFORM add_html USING '<table class="kpi"><tr>'.

  PERFORM int_to_str USING lv_sum CHANGING lv_str2.

  PERFORM add_kpi_card USING 'TOTAL OVERDUE DAYS (TOP 10)'
                             lv_str2
                             'Sum of overdue days per vendor'.

  PERFORM int_to_str USING lv_max CHANGING lv_str2.

  PERFORM add_kpi_card USING 'WORST VENDOR'
                             lv_worst
                             lv_str2.

  PERFORM int_to_str USING lv_avg CHANGING lv_str2.

  PERFORM add_kpi_card USING 'AVERAGE PER VENDOR'
                             lv_str2
                             'Overdue days average of shown vendors'.

  PERFORM int_to_str USING gv_overdue CHANGING lv_str2.

  PERFORM add_kpi_card USING 'OVERDUE PO ITEMS'
                             lv_str2
                             'Open items past delivery date'.

  PERFORM add_html USING '</tr></table>'.


*---------------------------------------------------------------------*
* CHART PANEL
*---------------------------------------------------------------------*

  PERFORM add_html USING '<div class="panel">'.
  PERFORM add_html USING '<div class="ptit">Top 10 Vendors by Total Overdue Days</div>'.
  PERFORM add_html USING '<div class="pnote">Hover a bar to see vendor details.'.
  PERFORM add_html USING ' Ranked descending &middot; X-axis = total overdue days,'.
  PERFORM add_html USING ' Y-axis = vendor name</div>'.

  PERFORM add_html USING '<table class="chart">'.


  CLEAR lv_rank.

  LOOP AT gt_vendor INTO gs_vendor.

    lv_rank = lv_rank + 1.

    PERFORM esc_html USING gs_vendor-name1 CHANGING lv_name.
    PERFORM date_to_str USING gs_vendor-oldest_eindt CHANGING lv_date.

    CLEAR lv_qty_char.

    WRITE gs_vendor-balance_qty TO lv_qty_char.
    CONDENSE lv_qty_char.
    lv_qty = lv_qty_char.


*---------------------------------------------------------------------*
* BAR LENGTH
*---------------------------------------------------------------------*

    lv_pct = gs_vendor-total_days * 100 / lv_max.

    IF lv_pct < 3.
      lv_pct = 3.
    ENDIF.

    IF lv_pct > 100.
      lv_pct = 100.
    ENDIF.


*---------------------------------------------------------------------*
* COLOUR BY RANK TIER
*---------------------------------------------------------------------*

    IF lv_rank <= 3.
      lv_fill = '#ff4d6d'.
      lv_glow = '#ff9166'.
    ELSEIF lv_rank <= 6.
      lv_fill = '#ffa03c'.
      lv_glow = '#ffd166'.
    ELSE.
      lv_fill = '#3f8cff'.
      lv_glow = '#5ad1ff'.
    ENDIF.


*---------------------------------------------------------------------*
* TOOLTIP
*---------------------------------------------------------------------*

    PERFORM int_to_str USING gs_vendor-total_days CHANGING lv_str2.

    CONCATENATE
      'Vendor' gs_vendor-lifnr '-' lv_name
      '| Total overdue days:' lv_str2
      INTO lv_tip SEPARATED BY space.

    PERFORM int_to_str USING gs_vendor-max_days CHANGING lv_str2.

    CONCATENATE
      lv_tip '| Worst item:' lv_str2 'days'
      INTO lv_tip SEPARATED BY space.

    PERFORM int_to_str USING gs_vendor-items CHANGING lv_str2.

    CONCATENATE
      lv_tip '| Overdue items:' lv_str2
      '| Open qty:' lv_qty
      '| Oldest delivery date:' lv_date
      '| Status:' gs_vendor-status
      INTO lv_tip SEPARATED BY space.


*---------------------------------------------------------------------*
* ROW
*---------------------------------------------------------------------*

    CONCATENATE '<tr class="row" title="' lv_tip '">' INTO lv_str.
    PERFORM add_html USING lv_str.

    PERFORM int_to_str USING lv_rank CHANGING lv_str2.

    IF lv_rank <= 3.

      CONCATENATE
        '<td class="rk"><span class="badge top3">'
        lv_str2 '</span></td>'
        INTO lv_str.

    ELSE.

      CONCATENATE
        '<td class="rk"><span class="badge">'
        lv_str2 '</span></td>'
        INTO lv_str.

    ENDIF.

    PERFORM add_html USING lv_str.


    PERFORM int_to_str USING gs_vendor-items CHANGING lv_str2.

    CONCATENATE
      '<td class="vend">' lv_name
      '<div class="vsub">Vendor ' gs_vendor-lifnr
      ' &middot; ' lv_str2 ' items &middot; oldest ' lv_date
      '</div></td>'
      INTO lv_str.

    PERFORM add_html USING lv_str.


    PERFORM int_to_str USING lv_pct CHANGING lv_str2.

    CONCATENATE
      '<td><div class="track"><div class="fill" style="width:'
      lv_str2 '%;background-color:' lv_fill
      ';background-image:linear-gradient(90deg,' lv_glow ',' lv_fill
      ');"></div></div></td>'
      INTO lv_str.

    PERFORM add_html USING lv_str.


    PERFORM int_to_str USING gs_vendor-total_days CHANGING lv_str2.

    CONCATENATE
      '<td class="val">' lv_str2
      '<span class="unit"> days</span></td></tr>'
      INTO lv_str.

    PERFORM add_html USING lv_str.

  ENDLOOP.


*---------------------------------------------------------------------*
* AXIS
*---------------------------------------------------------------------*

  PERFORM add_html USING '<tr><td class="rk"></td><td class="vend"></td>'.
  PERFORM add_html USING '<td><table class="axis"><tr>'.

  CLEAR lv_tick.
  PERFORM int_to_str USING lv_tick CHANGING lv_str2.

  CONCATENATE '<td>' lv_str2 '</td>' INTO lv_str.
  PERFORM add_html USING lv_str.

  lv_tick = lv_max / 4.
  PERFORM int_to_str USING lv_tick CHANGING lv_str2.

  CONCATENATE '<td>' lv_str2 '</td>' INTO lv_str.
  PERFORM add_html USING lv_str.

  lv_tick = lv_max / 2.
  PERFORM int_to_str USING lv_tick CHANGING lv_str2.

  CONCATENATE '<td>' lv_str2 '</td>' INTO lv_str.
  PERFORM add_html USING lv_str.

  lv_tick = lv_max * 3 / 4.
  PERFORM int_to_str USING lv_tick CHANGING lv_str2.

  CONCATENATE '<td>' lv_str2 '</td>' INTO lv_str.
  PERFORM add_html USING lv_str.

  PERFORM int_to_str USING lv_max CHANGING lv_str2.

  CONCATENATE '<td class="axr">' lv_str2 '</td>' INTO lv_str.
  PERFORM add_html USING lv_str.

  PERFORM add_html USING '</tr></table></td><td class="val"></td></tr>'.

  PERFORM add_html USING '</table>'.


*---------------------------------------------------------------------*
* FOOTER
*---------------------------------------------------------------------*

  CONCATENATE
    '<div class="foot">Report ZMM_PUR_ORDER_REPORT &middot; generated '
    lv_today
    ' &middot; red = ranks 1-3, amber = 4-6, blue = 7-10</div>'
    INTO lv_str.

  PERFORM add_html USING lv_str.

  PERFORM add_html USING '</div></div></body></html>'.

ENDFORM.


*---------------------------------------------------------------------*
* ADD KPI CARD
*---------------------------------------------------------------------*

FORM add_kpi_card
  USING
    p_label TYPE clike
    p_value TYPE clike
    p_note  TYPE clike.

  DATA:
    lv_line TYPE string.

  CONCATENATE
    '<td class="card" width="25%"><div class="klab">' p_label
    '</div><div class="kval">' p_value
    '</div><div class="kfoot">' p_note
    '</div></td>'
    INTO lv_line.

  PERFORM add_html USING lv_line.

ENDFORM.


*---------------------------------------------------------------------*
* APPEND HTML LINE
*---------------------------------------------------------------------*

FORM add_html
  USING p_line TYPE clike.

  CONCATENATE gv_html p_line cl_abap_char_utilities=>newline
    INTO gv_html.

ENDFORM.


*---------------------------------------------------------------------*
* ESCAPE HTML SPECIAL CHARACTERS
*---------------------------------------------------------------------*

FORM esc_html
  USING    p_in  TYPE clike
  CHANGING p_out TYPE string.

  DATA:
    lv_text TYPE string.

  lv_text = p_in.

  REPLACE ALL OCCURRENCES OF '&' IN lv_text WITH '&amp;'.
  REPLACE ALL OCCURRENCES OF '<' IN lv_text WITH '&lt;'.
  REPLACE ALL OCCURRENCES OF '>' IN lv_text WITH '&gt;'.
  REPLACE ALL OCCURRENCES OF '"' IN lv_text WITH '&quot;'.

  CONDENSE lv_text.

  p_out = lv_text.

ENDFORM.


*---------------------------------------------------------------------*
* INTEGER TO STRING
*---------------------------------------------------------------------*

FORM int_to_str
  USING    p_int TYPE i
  CHANGING p_str TYPE string.

  DATA:
    lv_char TYPE char20.

  lv_char = p_int.

  CONDENSE lv_char.

  p_str = lv_char.

ENDFORM.


*---------------------------------------------------------------------*
* DATE TO STRING
*---------------------------------------------------------------------*

FORM date_to_str
  USING    p_date TYPE d
  CHANGING p_str  TYPE string.

  DATA:
    lv_char TYPE char10.

  IF p_date IS INITIAL.
    p_str = '-'.
    RETURN.
  ENDIF.

  WRITE p_date TO lv_char.

  CONDENSE lv_char.

  p_str = lv_char.

ENDFORM.
