*&---------------------------------------------------------------------*
*& Report ZMM_OPEN_PO
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZMM_OPEN_PO.


*---------------------------------------------------------------------*
* Classic ECC 6.0 - PO Delivery Status Report
*---------------------------------------------------------------------*
* Purpose:
*   Display Purchase Orders with:
*   - Vendor
*   - Material
*   - Material Group
*   - Plant
*   - PO Quantity
*   - GR Quantity
*   - Balance Quantity
*   - Delivery Date
*   - Delivery Status
*   - Overdue Days
*   - Traffic Light
*
* Status:
*   GREEN  = Completely Delivered
*   YELLOW = Open / Partially Delivered / Not Delivered
*   RED    = Overdue
*
* ALV:
*   REUSE_ALV_GRID_DISPLAY
*---------------------------------------------------------------------*

TYPE-POOLS:
  slis.

TABLES:
  ekko,
  ekpo,
  eket,
  ekbe,
  lfa1,
  makt,
  t001w.

*---------------------------------------------------------------------*
* TYPE DECLARATIONS
*---------------------------------------------------------------------*

TYPES: BEGIN OF ty_output,

         ebeln         TYPE ekpo-ebeln,
         ebelp         TYPE ekpo-ebelp,

         bedat         TYPE ekko-bedat,

         lifnr         TYPE ekko-lifnr,
         name1         TYPE lfa1-name1,

         matnr         TYPE ekpo-matnr,
         maktx         TYPE makt-maktx,
         matkl         TYPE ekpo-matkl,

         werks         TYPE ekpo-werks,
         plant_name    TYPE t001w-name1,

         po_qty        TYPE ekpo-menge,
         gr_qty        TYPE ekpo-menge,
         balance_qty   TYPE ekpo-menge,

         meins         TYPE ekpo-meins,

         eindt         TYPE eket-eindt,

         overdue_days  TYPE i,

         status        TYPE char35,

         traffic       TYPE char4,

         netwr         TYPE ekpo-netwr,
         waers         TYPE ekko-waers,

         bsart         TYPE ekko-bsart,
         ekorg         TYPE ekko-ekorg,
         ekgrp         TYPE ekko-ekgrp,

       END OF ty_output.


TYPES: BEGIN OF ty_ekbe,

         ebeln TYPE ekbe-ebeln,
         ebelp TYPE ekbe-ebelp,
         menge TYPE ekbe-menge,
         shkzg TYPE ekbe-shkzg,
         vgabe TYPE ekbe-vgabe,

       END OF ty_ekbe.


TYPES: BEGIN OF ty_eket,

         ebeln TYPE eket-ebeln,
         ebelp TYPE eket-ebelp,
         eindt TYPE eket-eindt,

       END OF ty_eket.


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
* HISTOGRAM TYPES
*---------------------------------------------------------------------*

TYPES: BEGIN OF ty_histogram,

         bucket   TYPE char40,
         po_count TYPE i,

       END OF ty_histogram.


TYPES: BEGIN OF ty_graph,

         text(40) TYPE c,
         value    TYPE i,

       END OF ty_graph.


*---------------------------------------------------------------------*
* INTERNAL TABLES
*---------------------------------------------------------------------*

DATA:
  gt_output TYPE STANDARD TABLE OF ty_output,
  gs_output TYPE ty_output.

DATA:
  gt_ekbe TYPE STANDARD TABLE OF ty_ekbe,
  gs_ekbe TYPE ty_ekbe.

DATA:
  gt_eket TYPE STANDARD TABLE OF ty_eket,
  gs_eket TYPE ty_eket.

DATA:
  gt_lfa1 TYPE STANDARD TABLE OF ty_lfa1,
  gs_lfa1 TYPE ty_lfa1.

DATA:
  gt_makt TYPE STANDARD TABLE OF ty_makt,
  gs_makt TYPE ty_makt.

DATA:
  gt_t001w TYPE STANDARD TABLE OF ty_t001w,
  gs_t001w TYPE ty_t001w.


*---------------------------------------------------------------------*
* HISTOGRAM DATA
*---------------------------------------------------------------------*

DATA:
  gt_histogram TYPE STANDARD TABLE OF ty_histogram,
  gs_histogram TYPE ty_histogram.


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
* WORK VARIABLES
*---------------------------------------------------------------------*

DATA:
  gv_gr_qty TYPE ekbe-menge.

DATA:
  gv_subrc TYPE sy-subrc.


*---------------------------------------------------------------------*
* SUMMARY VARIABLES
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
  p_chart AS CHECKBOX DEFAULT space.

SELECTION-SCREEN END OF BLOCK b5.


*---------------------------------------------------------------------*
* START OF SELECTION
*---------------------------------------------------------------------*

START-OF-SELECTION.

  PERFORM get_data.

  IF gt_output[] IS INITIAL.

    MESSAGE 'No Purchase Orders found for the selection' TYPE 'I'.

    EXIT.

  ENDIF.

  PERFORM calculate_summary.

  PERFORM build_fieldcatalog.

  PERFORM build_sort.

  PERFORM display_alv.

  IF p_chart = 'X'.
    PERFORM prepare_histogram_data.
    PERFORM display_histogram.
  ENDIF.


*---------------------------------------------------------------------*
* GET DATA
*---------------------------------------------------------------------*

FORM get_data.

  DATA:
    lt_ekko TYPE STANDARD TABLE OF ekko,
    ls_ekko TYPE ekko.

  DATA:
    lt_ekpo TYPE STANDARD TABLE OF ekpo,
    ls_ekpo TYPE ekpo.


*---------------------------------------------------------------------*
* 1. READ PO HEADER
*---------------------------------------------------------------------*

  SELECT *
    INTO TABLE lt_ekko
    FROM ekko
    WHERE ebeln IN s_ebeln
      AND bedat IN s_bedat
      AND lifnr IN s_lifnr.

  IF lt_ekko[] IS INITIAL.

    RETURN.

  ENDIF.


*---------------------------------------------------------------------*
* 2. READ PO ITEMS
*---------------------------------------------------------------------*

  SELECT *
    INTO TABLE lt_ekpo
    FROM ekpo
    FOR ALL ENTRIES IN lt_ekko
    WHERE ebeln = lt_ekko-ebeln
      AND matnr IN s_matnr
      AND matkl IN s_matkl
      AND werks IN s_werks.

  IF lt_ekpo[] IS INITIAL.

    RETURN.

  ENDIF.


*---------------------------------------------------------------------*
* 3. READ PO HISTORY / GOODS RECEIPT
*---------------------------------------------------------------------*

  SELECT
    ebeln
    ebelp
    menge
    shkzg
    vgabe

    INTO TABLE gt_ekbe

    FROM ekbe

    FOR ALL ENTRIES IN lt_ekpo

    WHERE ebeln = lt_ekpo-ebeln
      AND ebelp = lt_ekpo-ebelp
      AND vgabe = '1'.


*---------------------------------------------------------------------*
* 4. READ SCHEDULE LINES
*---------------------------------------------------------------------*

  SELECT
    ebeln
    ebelp
    eindt

    INTO TABLE gt_eket

    FROM eket

    FOR ALL ENTRIES IN lt_ekpo

    WHERE ebeln = lt_ekpo-ebeln
      AND ebelp = lt_ekpo-ebelp.


*---------------------------------------------------------------------*
* 5. READ VENDOR
*---------------------------------------------------------------------*

  SELECT
    lifnr
    name1

    INTO TABLE gt_lfa1

    FROM lfa1

    FOR ALL ENTRIES IN lt_ekko

    WHERE lifnr = lt_ekko-lifnr.


*---------------------------------------------------------------------*
* 6. READ MATERIAL DESCRIPTION
*---------------------------------------------------------------------*

  SELECT
    matnr
    maktx

    INTO TABLE gt_makt

    FROM makt

    FOR ALL ENTRIES IN lt_ekpo

    WHERE matnr = lt_ekpo-matnr
      AND spras = sy-langu.


*---------------------------------------------------------------------*
* 7. READ PLANT DESCRIPTION
*---------------------------------------------------------------------*

  SELECT
    werks
    name1

    INTO TABLE gt_t001w

    FROM t001w

    FOR ALL ENTRIES IN lt_ekpo

    WHERE werks = lt_ekpo-werks.


*---------------------------------------------------------------------*
* 8. SORT TABLES
*---------------------------------------------------------------------*

  SORT gt_ekbe BY ebeln ebelp.
  SORT gt_eket BY ebeln ebelp eindt.
  SORT gt_lfa1 BY lifnr.
  SORT gt_makt BY matnr.
  SORT gt_t001w BY werks.


*---------------------------------------------------------------------*
* 9. BUILD OUTPUT
*---------------------------------------------------------------------*

  LOOP AT lt_ekpo INTO ls_ekpo.


*-------------------------------------------------------------------*
* Ignore deleted PO items
*-------------------------------------------------------------------*

    IF ls_ekpo-loekz IS NOT INITIAL.

      CONTINUE.

    ENDIF.


*-------------------------------------------------------------------*
* Read PO Header
*-------------------------------------------------------------------*

    CLEAR ls_ekko.

    READ TABLE lt_ekko
      INTO ls_ekko
      WITH KEY ebeln = ls_ekpo-ebeln.

    IF sy-subrc <> 0.

      CONTINUE.

    ENDIF.


*-------------------------------------------------------------------*
* Clear Output
*-------------------------------------------------------------------*

    CLEAR gs_output.


*-------------------------------------------------------------------*
* Basic PO information
*-------------------------------------------------------------------*

    gs_output-ebeln = ls_ekpo-ebeln.
    gs_output-ebelp = ls_ekpo-ebelp.

    gs_output-bedat = ls_ekko-bedat.

    gs_output-lifnr = ls_ekko-lifnr.

    gs_output-matnr = ls_ekpo-matnr.
    gs_output-matkl = ls_ekpo-matkl.

    gs_output-werks = ls_ekpo-werks.

    gs_output-po_qty = ls_ekpo-menge.

    gs_output-meins = ls_ekpo-meins.

    gs_output-netwr = ls_ekpo-netwr.
    gs_output-waers = ls_ekko-waers.

    gs_output-bsart = ls_ekko-bsart.
    gs_output-ekorg = ls_ekko-ekorg.
    gs_output-ekgrp = ls_ekko-ekgrp.


*-------------------------------------------------------------------*
* Vendor Name
*-------------------------------------------------------------------*

    CLEAR gs_lfa1.

    READ TABLE gt_lfa1
      INTO gs_lfa1
      WITH KEY lifnr = ls_ekko-lifnr
      BINARY SEARCH.

    IF sy-subrc = 0.

      gs_output-name1 = gs_lfa1-name1.

    ENDIF.


*-------------------------------------------------------------------*
* Material Description
*-------------------------------------------------------------------*

    CLEAR gs_makt.

    READ TABLE gt_makt
      INTO gs_makt
      WITH KEY matnr = ls_ekpo-matnr
      BINARY SEARCH.

    IF sy-subrc = 0.

      gs_output-maktx = gs_makt-maktx.

    ENDIF.


*-------------------------------------------------------------------*
* Plant Description
*-------------------------------------------------------------------*

    CLEAR gs_t001w.

    READ TABLE gt_t001w
      INTO gs_t001w
      WITH KEY werks = ls_ekpo-werks
      BINARY SEARCH.

    IF sy-subrc = 0.

      gs_output-plant_name = gs_t001w-name1.

    ENDIF.


*-------------------------------------------------------------------*
* Calculate GR Quantity
*-------------------------------------------------------------------*

    CLEAR gv_gr_qty.

    LOOP AT gt_ekbe INTO gs_ekbe

      WHERE ebeln = ls_ekpo-ebeln
        AND ebelp = ls_ekpo-ebelp.


      IF gs_ekbe-shkzg = 'S'.

        gv_gr_qty = gv_gr_qty + gs_ekbe-menge.

      ELSEIF gs_ekbe-shkzg = 'H'.

        gv_gr_qty = gv_gr_qty - gs_ekbe-menge.

      ENDIF.

    ENDLOOP.


*-------------------------------------------------------------------*
* Prevent negative GR quantity
*-------------------------------------------------------------------*

    IF gv_gr_qty < 0.

      CLEAR gv_gr_qty.

    ENDIF.


*-------------------------------------------------------------------*
* Store GR quantity
*-------------------------------------------------------------------*

    gs_output-gr_qty = gv_gr_qty.


*-------------------------------------------------------------------*
* Calculate Balance
*-------------------------------------------------------------------*

    gs_output-balance_qty =
      gs_output-po_qty - gs_output-gr_qty.


*-------------------------------------------------------------------*
* Prevent negative balance
*-------------------------------------------------------------------*

    IF gs_output-balance_qty < 0.

      CLEAR gs_output-balance_qty.

    ENDIF.


*-------------------------------------------------------------------*
* Get Delivery Date
*-------------------------------------------------------------------*

    CLEAR gs_output-eindt.

    LOOP AT gt_eket INTO gs_eket

      WHERE ebeln = ls_ekpo-ebeln
        AND ebelp = ls_ekpo-ebelp.


      IF gs_output-eindt IS INITIAL.

        gs_output-eindt = gs_eket-eindt.

      ELSE.

        IF gs_eket-eindt < gs_output-eindt.

          gs_output-eindt = gs_eket-eindt.

        ENDIF.

      ENDIF.

    ENDLOOP.


*-------------------------------------------------------------------*
* Delivery Date Selection
*-------------------------------------------------------------------*

    IF s_eindt[] IS NOT INITIAL.

      IF gs_output-eindt NOT IN s_eindt.

        CONTINUE.

      ENDIF.

    ENDIF.


*-------------------------------------------------------------------*
* Determine Status
*-------------------------------------------------------------------*

    PERFORM determine_status.


*-------------------------------------------------------------------*
* Apply Radio Button Filter
*-------------------------------------------------------------------*

    PERFORM apply_status_filter.

    IF gv_subrc <> 0.

      CONTINUE.

    ENDIF.


*-------------------------------------------------------------------*
* Append Output
*-------------------------------------------------------------------*

    APPEND gs_output TO gt_output.

  ENDLOOP.


ENDFORM.


*---------------------------------------------------------------------*
* DETERMINE STATUS
*---------------------------------------------------------------------*

FORM determine_status.

  CLEAR:
    gs_output-status,
    gs_output-traffic,
    gs_output-overdue_days.


*---------------------------------------------------------------------*
* COMPLETE
*---------------------------------------------------------------------*

  IF gs_output-gr_qty >= gs_output-po_qty.

    gs_output-status  = 'COMPLETELY DELIVERED'.
    gs_output-traffic = c_green.

    CLEAR gs_output-overdue_days.


*---------------------------------------------------------------------*
* PARTIALLY DELIVERED
*---------------------------------------------------------------------*

  ELSEIF gs_output-gr_qty > 0.

    IF gs_output-eindt IS NOT INITIAL
       AND gs_output-eindt < sy-datum.

      gs_output-status  = 'PARTIAL / OVERDUE'.
      gs_output-traffic = c_red.

      gs_output-overdue_days =
        sy-datum - gs_output-eindt.

    ELSE.

      gs_output-status  = 'PARTIALLY DELIVERED'.
      gs_output-traffic = c_yellow.

      CLEAR gs_output-overdue_days.

    ENDIF.


*---------------------------------------------------------------------*
* NOT DELIVERED
*---------------------------------------------------------------------*

  ELSE.

    IF gs_output-eindt IS NOT INITIAL
       AND gs_output-eindt < sy-datum.

      gs_output-status  = 'NOT DELIVERED / OVERDUE'.
      gs_output-traffic = c_red.

      gs_output-overdue_days =
        sy-datum - gs_output-eindt.

    ELSE.

      gs_output-status  = 'NOT DELIVERED'.
      gs_output-traffic = c_yellow.

      CLEAR gs_output-overdue_days.

    ENDIF.

  ENDIF.

ENDFORM.


*---------------------------------------------------------------------*
* APPLY RADIO BUTTON FILTER
*---------------------------------------------------------------------*

FORM apply_status_filter.

  CLEAR gv_subrc.


*---------------------------------------------------------------------*
* ALL
*---------------------------------------------------------------------*

  IF p_all = 'X'.

    gv_subrc = 0.

    RETURN.

  ENDIF.


*---------------------------------------------------------------------*
* OPEN
*---------------------------------------------------------------------*

  IF p_open = 'X'.

    IF gs_output-balance_qty > 0.

      gv_subrc = 0.

    ELSE.

      gv_subrc = 4.

    ENDIF.

    RETURN.

  ENDIF.


*---------------------------------------------------------------------*
* COMPLETE
*---------------------------------------------------------------------*

  IF p_comp = 'X'.

    IF gs_output-status = 'COMPLETELY DELIVERED'.

      gv_subrc = 0.

    ELSE.

      gv_subrc = 4.

    ENDIF.

    RETURN.

  ENDIF.


*---------------------------------------------------------------------*
* PARTIAL
*---------------------------------------------------------------------*

  IF p_part = 'X'.

    IF gs_output-gr_qty > 0
       AND gs_output-balance_qty > 0.

      gv_subrc = 0.

    ELSE.

      gv_subrc = 4.

    ENDIF.

    RETURN.

  ENDIF.


*---------------------------------------------------------------------*
* NOT DELIVERED
*---------------------------------------------------------------------*

  IF p_nogr = 'X'.

    IF gs_output-gr_qty = 0.

      gv_subrc = 0.

    ELSE.

      gv_subrc = 4.

    ENDIF.

    RETURN.

  ENDIF.


*---------------------------------------------------------------------*
* OVERDUE
*---------------------------------------------------------------------*

  IF p_over = 'X'.

    IF gs_output-balance_qty > 0
       AND gs_output-eindt IS NOT INITIAL
       AND gs_output-eindt < sy-datum.

      gv_subrc = 0.

    ELSE.

      gv_subrc = 4.

    ENDIF.

    RETURN.

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

    "---------------------------------------------------------------*
    " Total
    "---------------------------------------------------------------*

    gv_total = gv_total + 1.

    "---------------------------------------------------------------*
    " Completely Delivered
    "---------------------------------------------------------------*

    IF ls_summary-status = 'COMPLETELY DELIVERED'.

      gv_complete = gv_complete + 1.

    "---------------------------------------------------------------*
    " Partially Delivered
    "---------------------------------------------------------------*

    ELSEIF ls_summary-status = 'PARTIALLY DELIVERED'
        OR ls_summary-status = 'PARTIAL / OVERDUE'.

      gv_partial = gv_partial + 1.

    "---------------------------------------------------------------*
    " Not Delivered
    "---------------------------------------------------------------*

    ELSEIF ls_summary-status = 'NOT DELIVERED'
        OR ls_summary-status = 'NOT DELIVERED / OVERDUE'.

      gv_not_delivered = gv_not_delivered + 1.

    ENDIF.

    "---------------------------------------------------------------*
    " Overdue
    "---------------------------------------------------------------*

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

  CLEAR gt_fieldcat.


*---------------------------------------------------------------------*
* PO NUMBER
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'EBELN'
    'PO Number'
    12
    'X'
    'X'.


*---------------------------------------------------------------------*
* PO ITEM
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'EBELP'
    'Item'
    6
    'X'
    space.


*---------------------------------------------------------------------*
* PO DATE
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'BEDAT'
    'PO Date'
    10
    'X'
    space.


*---------------------------------------------------------------------*
* VENDOR
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'LIFNR'
    'Vendor'
    10
    'X'
    space.


*---------------------------------------------------------------------*
* VENDOR NAME
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'NAME1'
    'Vendor Name'
    25
    space
    space.


*---------------------------------------------------------------------*
* MATERIAL
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'MATNR'
    'Material'
    18
    'X'
    space.


*---------------------------------------------------------------------*
* MATERIAL DESCRIPTION
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'MAKTX'
    'Material Description'
    30
    space
    space.


*---------------------------------------------------------------------*
* MATERIAL GROUP
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'MATKL'
    'Material Group'
    12
    'X'
    space.


*---------------------------------------------------------------------*
* PLANT
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'WERKS'
    'Plant'
    8
    'X'
    space.


*---------------------------------------------------------------------*
* PLANT NAME
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'PLANT_NAME'
    'Plant Name'
    25
    space
    space.


*---------------------------------------------------------------------*
* PO QUANTITY
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'PO_QTY'
    'PO Quantity'
    15
    space
    space.


*---------------------------------------------------------------------*
* GR QUANTITY
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'GR_QTY'
    'GR Quantity'
    15
    space
    space.


*---------------------------------------------------------------------*
* BALANCE QUANTITY
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'BALANCE_QTY'
    'Balance Quantity'
    15
    space
    space.


*---------------------------------------------------------------------*
* UOM
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'MEINS'
    'UOM'
    6
    space
    space.


*---------------------------------------------------------------------*
* DELIVERY DATE
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'EINDT'
    'Delivery Date'
    12
    'X'
    space.


*---------------------------------------------------------------------*
* OVERDUE DAYS
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'OVERDUE_DAYS'
    'Overdue Days'
    12
    space
    space.


*---------------------------------------------------------------------*
* STATUS
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'STATUS'
    'Delivery Status'
    30
    'X'
    space.


*---------------------------------------------------------------------*
* TRAFFIC LIGHT
*---------------------------------------------------------------------*

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'TRAFFIC'.
  gs_fieldcat-seltext_m = 'Traffic'.
  gs_fieldcat-seltext_l = 'Traffic Light'.
  gs_fieldcat-outputlen = 8.
  gs_fieldcat-icon      = 'X'.
  gs_fieldcat-just      = 'C'.

  APPEND gs_fieldcat TO gt_fieldcat.


*---------------------------------------------------------------------*
* NET VALUE
*---------------------------------------------------------------------*

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = 'NETWR'.
  gs_fieldcat-seltext_m = 'Net Value'.
  gs_fieldcat-outputlen = 15.
  gs_fieldcat-do_sum    = 'X'.
  gs_fieldcat-cfieldname = 'WAERS'.

  APPEND gs_fieldcat TO gt_fieldcat.


*---------------------------------------------------------------------*
* CURRENCY
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'WAERS'
    'Currency'
    8
    space
    space.


*---------------------------------------------------------------------*
* PO TYPE
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'BSART'
    'PO Type'
    8
    space
    space.


*---------------------------------------------------------------------*
* PURCHASING ORGANIZATION
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'EKORG'
    'Purchasing Org.'
    12
    space
    space.


*---------------------------------------------------------------------*
* PURCHASING GROUP
*---------------------------------------------------------------------*

  PERFORM add_field USING
    'EKGRP'
    'Purchasing Group'
    12
    space
    space.

ENDFORM.


*---------------------------------------------------------------------*
* ADD FIELD TO FIELD CATALOG
*---------------------------------------------------------------------*

FORM add_field USING
      p_fieldname
      p_text
      p_outputlen
      p_key
      p_hotspot.

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = p_fieldname.
  gs_fieldcat-seltext_m = p_text.
  gs_fieldcat-seltext_l = p_text.
  gs_fieldcat-outputlen = p_outputlen.
  gs_fieldcat-key       = p_key.
  gs_fieldcat-hotspot   = p_hotspot.

  APPEND gs_fieldcat TO gt_fieldcat.

ENDFORM.


*---------------------------------------------------------------------*
* BUILD SORT
*---------------------------------------------------------------------*

FORM build_sort.

  CLEAR gt_sort.


*---------------------------------------------------------------------*
* Traffic
*---------------------------------------------------------------------*

  CLEAR gs_sort.

  gs_sort-fieldname = 'TRAFFIC'.
  gs_sort-up        = 'X'.

  APPEND gs_sort TO gt_sort.


*---------------------------------------------------------------------*
* Plant
*---------------------------------------------------------------------*

  CLEAR gs_sort.

  gs_sort-fieldname = 'WERKS'.
  gs_sort-up        = 'X'.

  APPEND gs_sort TO gt_sort.


*---------------------------------------------------------------------*
* Vendor
*---------------------------------------------------------------------*

  CLEAR gs_sort.

  gs_sort-fieldname = 'LIFNR'.
  gs_sort-up        = 'X'.

  APPEND gs_sort TO gt_sort.


*---------------------------------------------------------------------*
* Delivery Date
*---------------------------------------------------------------------*

  CLEAR gs_sort.

  gs_sort-fieldname = 'EINDT'.
  gs_sort-up        = 'X'.

  APPEND gs_sort TO gt_sort.


*---------------------------------------------------------------------*
* PO Number
*---------------------------------------------------------------------*

  CLEAR gs_sort.

  gs_sort-fieldname = 'EBELN'.
  gs_sort-up        = 'X'.

  APPEND gs_sort TO gt_sort.

ENDFORM.


*---------------------------------------------------------------------*
* DISPLAY ALV
*---------------------------------------------------------------------*

FORM display_alv.

  gv_repid = sy-repid.


*-------------------------------------------------------------------*
* Layout
*-------------------------------------------------------------------*

  CLEAR gs_layout.

  gs_layout-zebra             = 'X'.
  gs_layout-colwidth_optimize = 'X'.
  gs_layout-detail_popup      = 'X'.


*-------------------------------------------------------------------*
* Events
*-------------------------------------------------------------------*

  CLEAR gt_events.

  CALL FUNCTION 'REUSE_ALV_EVENTS_GET'
    EXPORTING
      i_list_type = 0
    IMPORTING
      et_events   = gt_events.


  READ TABLE gt_events
    INTO gs_event
    WITH KEY name = 'TOP_OF_PAGE'.

  IF sy-subrc = 0.

    gs_event-form = 'TOP_OF_PAGE'.

    MODIFY gt_events
      FROM gs_event
      INDEX sy-tabix.

  ENDIF.


*-------------------------------------------------------------------*
* Display ALV
*-------------------------------------------------------------------*

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
      program_error           = 1
      OTHERS                  = 2.


  IF sy-subrc <> 0.

    MESSAGE 'Error while displaying ALV' TYPE 'E'.

  ENDIF.

ENDFORM.


*---------------------------------------------------------------------*
* TOP OF PAGE
*---------------------------------------------------------------------*

FORM top_of_page.

  DATA:
    lt_header TYPE slis_t_listheader,
    ls_header TYPE slis_listheader.


*-------------------------------------------------------------------*
* Convert counters to character
*-------------------------------------------------------------------*

  WRITE gv_total
    TO gv_total_c.

  WRITE gv_complete
    TO gv_complete_c.

  WRITE gv_partial
    TO gv_partial_c.

  WRITE gv_not_delivered
    TO gv_not_delivered_c.

  WRITE gv_overdue
    TO gv_overdue_c.


*-------------------------------------------------------------------*
* Main Title
*-------------------------------------------------------------------*

  CLEAR ls_header.

  ls_header-typ  = 'H'.
  ls_header-info = 'PO DELIVERY STATUS DASHBOARD'.

  APPEND ls_header TO lt_header.


*-------------------------------------------------------------------*
* Report Date
*-------------------------------------------------------------------*

  CLEAR ls_header.

  ls_header-typ = 'S'.

  CONCATENATE
    'Report Date:'
    sy-datum
    INTO ls_header-info
    SEPARATED BY space.

  APPEND ls_header TO lt_header.


*-------------------------------------------------------------------*
* Total
*-------------------------------------------------------------------*

  CLEAR ls_header.

  ls_header-typ = 'S'.

  CONCATENATE
    'Total PO Items:'
    gv_total_c
    INTO ls_header-info
    SEPARATED BY space.

  APPEND ls_header TO lt_header.


*-------------------------------------------------------------------*
* Complete
*-------------------------------------------------------------------*

  CLEAR ls_header.

  ls_header-typ = 'S'.

  CONCATENATE
    'Completely Delivered:'
    gv_complete_c
    INTO ls_header-info
    SEPARATED BY space.

  APPEND ls_header TO lt_header.


*-------------------------------------------------------------------*
* Partial
*-------------------------------------------------------------------*

  CLEAR ls_header.

  ls_header-typ = 'S'.

  CONCATENATE
    'Partially Delivered:'
    gv_partial_c
    INTO ls_header-info
    SEPARATED BY space.

  APPEND ls_header TO lt_header.


*-------------------------------------------------------------------*
* Not Delivered
*-------------------------------------------------------------------*

  CLEAR ls_header.

  ls_header-typ = 'S'.

  CONCATENATE
    'Not Delivered:'
    gv_not_delivered_c
    INTO ls_header-info
    SEPARATED BY space.

  APPEND ls_header TO lt_header.


*-------------------------------------------------------------------*
* Overdue
*-------------------------------------------------------------------*

  CLEAR ls_header.

  ls_header-typ = 'S'.

  CONCATENATE
    'Overdue:'
    gv_overdue_c
    INTO ls_header-info
    SEPARATED BY space.

  APPEND ls_header TO lt_header.


*-------------------------------------------------------------------*
* Write ALV Header
*-------------------------------------------------------------------*

  CALL FUNCTION 'REUSE_ALV_COMMENTARY_WRITE'
    EXPORTING
      it_list_commentary = lt_header.

ENDFORM.


*---------------------------------------------------------------------*
* USER COMMAND
*---------------------------------------------------------------------*

FORM user_command USING
      r_ucomm     LIKE sy-ucomm
      rs_selfield TYPE slis_selfield.


  CASE r_ucomm.


*-------------------------------------------------------------------*
* Double Click
*-------------------------------------------------------------------*

    WHEN '&IC1'.

      IF rs_selfield-fieldname = 'EBELN'.

        READ TABLE gt_output
          INTO gs_output
          INDEX rs_selfield-tabindex.

        IF sy-subrc = 0.

          SET PARAMETER ID 'BES'
            FIELD gs_output-ebeln.

          CALL TRANSACTION 'ME23N'
            AND SKIP FIRST SCREEN.

        ENDIF.

      ENDIF.

  ENDCASE.

ENDFORM.


*---------------------------------------------------------------------*
* PREPARE HISTOGRAM DATA
*---------------------------------------------------------------------*

FORM prepare_histogram_data.

  DATA:
    ls_bucket TYPE ty_histogram,
    lv_index  TYPE i.

  REFRESH gt_histogram.

*-------------------------------------------------------------------*
* Initialize all six buckets
*-------------------------------------------------------------------*

  CLEAR ls_bucket.

  ls_bucket-bucket   = 'Not Overdue'.
  ls_bucket-po_count = 0.
  APPEND ls_bucket TO gt_histogram.

  ls_bucket-bucket   = '1-7 Days'.
  ls_bucket-po_count = 0.
  APPEND ls_bucket TO gt_histogram.

  ls_bucket-bucket   = '8-30 Days'.
  ls_bucket-po_count = 0.
  APPEND ls_bucket TO gt_histogram.

  ls_bucket-bucket   = '31-60 Days'.
  ls_bucket-po_count = 0.
  APPEND ls_bucket TO gt_histogram.

  ls_bucket-bucket   = '61-90 Days'.
  ls_bucket-po_count = 0.
  APPEND ls_bucket TO gt_histogram.

  ls_bucket-bucket   = '91+ Days'.
  ls_bucket-po_count = 0.
  APPEND ls_bucket TO gt_histogram.


*-------------------------------------------------------------------*
* Distribute PO items into buckets
*-------------------------------------------------------------------*

  LOOP AT gt_output INTO gs_output.

    IF gs_output-overdue_days <= 0.
      lv_index = 1.
    ELSEIF gs_output-overdue_days <= 7.
      lv_index = 2.
    ELSEIF gs_output-overdue_days <= 30.
      lv_index = 3.
    ELSEIF gs_output-overdue_days <= 60.
      lv_index = 4.
    ELSEIF gs_output-overdue_days <= 90.
      lv_index = 5.
    ELSE.
      lv_index = 6.
    ENDIF.

    READ TABLE gt_histogram INDEX lv_index INTO ls_bucket.
    IF sy-subrc = 0.
      ls_bucket-po_count = ls_bucket-po_count + 1.
      MODIFY gt_histogram FROM ls_bucket INDEX lv_index.
    ENDIF.

  ENDLOOP.

ENDFORM.


*---------------------------------------------------------------------*
* DISPLAY HISTOGRAM
*---------------------------------------------------------------------*

FORM display_histogram.

  DATA:
    lt_graph TYPE STANDARD TABLE OF ty_graph,
    ls_graph TYPE ty_graph.

  IF p_chart <> 'X'.
    RETURN.
  ENDIF.

  IF gt_histogram[] IS INITIAL.
    MESSAGE 'No histogram data available' TYPE 'I'.
    RETURN.
  ENDIF.


*-------------------------------------------------------------------*
* Convert histogram table to graph format
*-------------------------------------------------------------------*

  LOOP AT gt_histogram INTO gs_histogram.

    ls_graph-text  = gs_histogram-bucket.
    ls_graph-value = gs_histogram-po_count.
    APPEND ls_graph TO lt_graph.

  ENDLOOP.


*-------------------------------------------------------------------*
* Show 2D business graphic
*-------------------------------------------------------------------*

  CALL FUNCTION 'GRAPH_2D'
    EXPORTING
      titl = 'PO Delivery Delay Histogram'
      valt = 'Number of PO Items'
    TABLES
      data = lt_graph
    EXCEPTIONS
      gui_refuse_graphic = 1
      OTHERS             = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Error displaying histogram' TYPE 'I'.
  ENDIF.

ENDFORM.
