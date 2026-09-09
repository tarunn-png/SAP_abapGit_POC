*&---------------------------------------------------------------------*
*& Report ZMM_OPEN_PO_09
*&---------------------------------------------------------------------*
*& Open Purchase Order Delivery Status Report
*& SAP ECC 6.0 - Classic ABAP
*&---------------------------------------------------------------------*

REPORT zmm_open_po_09.

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
* ALV DATA
*---------------------------------------------------------------------*

DATA:
  gt_fieldcat TYPE slis_t_fieldcat_alv,
  gs_fieldcat TYPE slis_fieldcat_alv.

DATA:
  gt_sort TYPE slis_t_sortinfo_alv,
  gs_sort TYPE slis_sortinfo_alv.

DATA:
  gs_layout TYPE slis_layout_alv.

DATA:
  gv_repid TYPE sy-repid.

*---------------------------------------------------------------------*
* SELECTION SCREEN
*---------------------------------------------------------------------*

SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME.

SELECT-OPTIONS:
  s_ebeln FOR ekko-ebeln,
  s_bedat FOR ekko-bedat,
  s_lifnr FOR ekko-lifnr,
  s_matnr FOR ekpo-matnr,
  s_matkl FOR ekpo-matkl,
  s_werks FOR ekpo-werks.

SELECTION-SCREEN END OF BLOCK b1.

SELECTION-SCREEN BEGIN OF BLOCK b2 WITH FRAME.

SELECT-OPTIONS:
  s_eindt FOR eket-eindt.

SELECTION-SCREEN END OF BLOCK b2.

SELECTION-SCREEN BEGIN OF BLOCK b3 WITH FRAME.

PARAMETERS:
  p_all  RADIOBUTTON GROUP r1 DEFAULT 'X',
  p_open RADIOBUTTON GROUP r1,
  p_comp RADIOBUTTON GROUP r1,
  p_part RADIOBUTTON GROUP r1,
  p_nogr RADIOBUTTON GROUP r1,
  p_over RADIOBUTTON GROUP r1.

SELECTION-SCREEN END OF BLOCK b3.

SELECTION-SCREEN BEGIN OF BLOCK b4 WITH FRAME.

PARAMETERS:
  p_sort AS CHECKBOX DEFAULT 'X'.

SELECTION-SCREEN END OF BLOCK b4.

*---------------------------------------------------------------------*
* START OF SELECTION
*---------------------------------------------------------------------*

START-OF-SELECTION.

  PERFORM get_data.

  IF gt_output[] IS INITIAL.
    MESSAGE 'No Purchase Orders found for the selection' TYPE 'I'.
    EXIT.
  ENDIF.

  PERFORM build_fieldcatalog.
  PERFORM build_sort.
  PERFORM display_alv.

*---------------------------------------------------------------------*
* GET DATA
*---------------------------------------------------------------------*

FORM get_data.

*---------------------------------------------------------------------*
* 1. GET PO HEADER DATA
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
* SORT FOR BINARY SEARCH
*---------------------------------------------------------------------*

  SORT gt_ekko BY ebeln.

*---------------------------------------------------------------------*
* 2. GET PO ITEM DATA
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
* 3. REMOVE DELETED PO ITEMS
*---------------------------------------------------------------------*

  DELETE gt_ekpo WHERE loekz IS NOT INITIAL.

  IF gt_ekpo[] IS INITIAL.
    RETURN.
  ENDIF.

*---------------------------------------------------------------------*
* 4. GET PO HISTORY - GOODS RECEIPTS
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
* 5. AGGREGATE GR QUANTITY
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

        gs_gr-gr_qty =
          gs_gr-gr_qty + gs_ekbe-menge.

      ELSEIF gs_ekbe-shkzg = 'H'.

        gs_gr-gr_qty =
          gs_gr-gr_qty - gs_ekbe-menge.

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
* 7. GET EARLIEST DELIVERY DATE
*---------------------------------------------------------------------*

  IF gt_eket[] IS NOT INITIAL.

    SORT gt_eket BY ebeln ebelp eindt.

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

  IF gt_ekko[] IS NOT INITIAL.

    SELECT lifnr
           name1
      INTO TABLE gt_lfa1
      FROM lfa1
      FOR ALL ENTRIES IN gt_ekko
      WHERE lifnr = gt_ekko-lifnr.

  ENDIF.

*---------------------------------------------------------------------*
* 9. GET MATERIAL DESCRIPTION
*---------------------------------------------------------------------*

  IF gt_ekpo[] IS NOT INITIAL.

    SELECT matnr
           maktx
      INTO TABLE gt_makt
      FROM makt
      FOR ALL ENTRIES IN gt_ekpo
      WHERE matnr = gt_ekpo-matnr
        AND spras = sy-langu.

  ENDIF.

*---------------------------------------------------------------------*
* 10. GET PLANT DESCRIPTION
*---------------------------------------------------------------------*

  IF gt_ekpo[] IS NOT INITIAL.

    SELECT werks
           name1
      INTO TABLE gt_t001w
      FROM t001w
      FOR ALL ENTRIES IN gt_ekpo
      WHERE werks = gt_ekpo-werks.

  ENDIF.

*---------------------------------------------------------------------*
* 11. BUILD FINAL OUTPUT
*---------------------------------------------------------------------*

  LOOP AT gt_ekpo INTO gs_ekpo.

    CLEAR gs_output.

*---------------------------------------------------------------------*
* PO ITEM DATA
*---------------------------------------------------------------------*

    gs_output-ebeln = gs_ekpo-ebeln.
    gs_output-ebelp = gs_ekpo-ebelp.
    gs_output-matnr = gs_ekpo-matnr.
    gs_output-matkl = gs_ekpo-matkl.
    gs_output-werks = gs_ekpo-werks.
    gs_output-po_qty = gs_ekpo-menge.
    gs_output-meins = gs_ekpo-meins.
    gs_output-netwr = gs_ekpo-netwr.

*---------------------------------------------------------------------*
* PO HEADER DATA
*---------------------------------------------------------------------*

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
* VENDOR NAME
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
* PLANT NAME
*---------------------------------------------------------------------*

    READ TABLE gt_t001w INTO gs_t001w
      WITH TABLE KEY werks = gs_output-werks.

    IF sy-subrc = 0.

      gs_output-plant_name = gs_t001w-name1.

    ENDIF.

*---------------------------------------------------------------------*
* GOODS RECEIPT QUANTITY
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
* BALANCE QUANTITY
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
* DELIVERY DATE FILTER
*---------------------------------------------------------------------*

    IF s_eindt[] IS NOT INITIAL.

      IF gs_output-eindt NOT IN s_eindt.

        CONTINUE.

      ENDIF.

    ENDIF.

*---------------------------------------------------------------------*
* DETERMINE DELIVERY STATUS
*---------------------------------------------------------------------*

    PERFORM determine_status.

*---------------------------------------------------------------------*
* APPLY STATUS FILTER
*---------------------------------------------------------------------*

    PERFORM apply_status_filter.

    IF sy-subrc <> 0.

      CONTINUE.

    ENDIF.

*---------------------------------------------------------------------*
* APPEND OUTPUT
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

*---------------------------------------------------------------------*
* PARTIALLY DELIVERED
*---------------------------------------------------------------------*

  ELSEIF gs_output-gr_qty > 0.

    IF gs_output-eindt IS NOT INITIAL
       AND gs_output-eindt < sy-datum.

      gs_output-status = 'PARTIAL / OVERDUE'.

      gs_output-overdue_days =
        sy-datum - gs_output-eindt.

    ELSE.

      gs_output-status = 'PARTIALLY DELIVERED'.

    ENDIF.

*---------------------------------------------------------------------*
* NOT DELIVERED
*---------------------------------------------------------------------*

  ELSE.

    IF gs_output-eindt IS NOT INITIAL
       AND gs_output-eindt < sy-datum.

      gs_output-status = 'NOT DELIVERED / OVERDUE'.

      gs_output-overdue_days =
        sy-datum - gs_output-eindt.

    ELSE.

      gs_output-status = 'NOT DELIVERED'.

    ENDIF.

  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
* STATUS FILTER
*---------------------------------------------------------------------*

FORM apply_status_filter.

  sy-subrc = 0.

*---------------------------------------------------------------------*
* ALL
*---------------------------------------------------------------------*

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
* BUILD FIELD CATALOG
*---------------------------------------------------------------------*

FORM build_fieldcatalog.

  CLEAR gt_fieldcat[].

  PERFORM add_field USING:
    'EBELN'        'PO Number'       12 '',
    'EBELP'        'Item'             6 '',
    'BEDAT'        'PO Date'         10 '',
    'LIFNR'        'Vendor'          10 '',
    'NAME1'        'Vendor Name'     25 '',
    'MATNR'        'Material'        18 '',
    'MAKTX'        'Material Desc.'  30 '',
    'MATKL'        'Mat. Group'       10 '',
    'WERKS'        'Plant'             6 '',
    'PLANT_NAME'   'Plant Name'       20 '',
    'PO_QTY'       'PO Qty'           12 '',
    'GR_QTY'       'GR Qty'           12 '',
    'BALANCE_QTY'  'Balance Qty'      12 '',
    'MEINS'        'UoM'                5 '',
    'EINDT'        'Delivery Date'    12 '',
    'OVERDUE_DAYS' 'Overdue Days'     12 '',
    'STATUS'       'Delivery Status'  25 '',
    'NETWR'        'Net Value'        15 '',
    'WAERS'        'Currency'           8 '',
    'BSART'        'PO Type'            8 '',
    'EKORG'        'Purch. Org.'       10 '',
    'EKGRP'        'Purch. Group'      10 ''.

*---------------------------------------------------------------------*
* QUANTITY SETTINGS
*---------------------------------------------------------------------*

  PERFORM set_quantity_field USING 'PO_QTY'.
  PERFORM set_quantity_field USING 'GR_QTY'.
  PERFORM set_quantity_field USING 'BALANCE_QTY'.

*---------------------------------------------------------------------*
* NET VALUE TOTAL
*---------------------------------------------------------------------*

  READ TABLE gt_fieldcat INTO gs_fieldcat
    WITH KEY fieldname = 'NETWR'.

  IF sy-subrc = 0.

    gs_fieldcat-do_sum = 'X'.
    gs_fieldcat-cfieldname = 'WAERS'.

    MODIFY gt_fieldcat FROM gs_fieldcat
      INDEX sy-tabix.

  ENDIF.

*---------------------------------------------------------------------*
* PO NUMBER AS KEY
*---------------------------------------------------------------------*

  READ TABLE gt_fieldcat INTO gs_fieldcat
    WITH KEY fieldname = 'EBELN'.

  IF sy-subrc = 0.

    gs_fieldcat-key = 'X'.

    MODIFY gt_fieldcat FROM gs_fieldcat
      INDEX sy-tabix.

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

    MODIFY gt_fieldcat FROM gs_fieldcat
      INDEX sy-tabix.

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

*---------------------------------------------------------------------*
* PLANT
*---------------------------------------------------------------------*

  CLEAR gs_sort.

  gs_sort-fieldname = 'WERKS'.
  gs_sort-up        = 'X'.
  gs_sort-subtot    = 'X'.

  APPEND gs_sort TO gt_sort.

*---------------------------------------------------------------------*
* VENDOR
*---------------------------------------------------------------------*

  CLEAR gs_sort.

  gs_sort-fieldname = 'LIFNR'.
  gs_sort-up        = 'X'.

  APPEND gs_sort TO gt_sort.

*---------------------------------------------------------------------*
* DELIVERY DATE
*---------------------------------------------------------------------*

  CLEAR gs_sort.

  gs_sort-fieldname = 'EINDT'.
  gs_sort-up        = 'X'.

  APPEND gs_sort TO gt_sort.

ENDFORM.

*---------------------------------------------------------------------*
* DISPLAY ALV
*---------------------------------------------------------------------*

FORM display_alv.

  gv_repid = sy-repid.

  CLEAR gs_layout.

  gs_layout-zebra             = 'X'.
  gs_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program      = gv_repid
      i_callback_user_command = 'USER_COMMAND'
      is_layout               = gs_layout
      it_fieldcat             = gt_fieldcat
      it_sort                 = gt_sort
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
* USER COMMAND
*---------------------------------------------------------------------*
* Double-click PO Number -> ME23N
*---------------------------------------------------------------------*

FORM user_command
  USING
    p_ucomm    LIKE sy-ucomm
    p_selfield TYPE slis_selfield.

  DATA:
    lv_ebeln TYPE ekpo-ebeln.

  IF p_ucomm = '&IC1'.

    IF p_selfield-fieldname = 'EBELN'.

      READ TABLE gt_output INTO gs_output
        INDEX p_selfield-tabindex.

      IF sy-subrc = 0.

        lv_ebeln = gs_output-ebeln.

        SET PARAMETER ID 'BES'
          FIELD lv_ebeln.

        CALL TRANSACTION 'ME23N'
          AND SKIP FIRST SCREEN.

      ENDIF.

    ENDIF.

  ENDIF.

ENDFORM.
