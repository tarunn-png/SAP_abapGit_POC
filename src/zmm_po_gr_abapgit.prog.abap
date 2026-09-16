*&---------------------------------------------------------------------*
*& Report ZMM_PO_GR_ABAPGIT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZMM_PO_GR_ABAPGIT.

*&---------------------------------------------------------------------*
*& Report  ZMM_PO_GR_MIRO_STATUS
*&
*& Purpose:
*&   PO -> GR -> MIRO -> Vendor Payment Status
*&
*& SAP Version:
*&   ECC 6.0 - Classic ABAP syntax
*&---------------------------------------------------------------------*



TYPE-POOLS: slis.
tables: ekko,ekpo.

*---------------------------------------------------------------------*
* Selection Screen
*---------------------------------------------------------------------*

SELECT-OPTIONS:
  s_ebeln FOR ekko-ebeln,
  s_lifnr FOR ekko-lifnr,
  s_bukrs FOR ekko-bukrs,
  s_werks FOR ekpo-werks,
  s_bedat FOR ekko-bedat.

PARAMETERS:
  p_all   RADIOBUTTON GROUP g1 DEFAULT 'X',
  p_paid  RADIOBUTTON GROUP g1,
  p_npay  RADIOBUTTON GROUP g1,
  p_invp  RADIOBUTTON GROUP g1,
  p_grp   RADIOBUTTON GROUP g1.

*---------------------------------------------------------------------*
* Constants
*---------------------------------------------------------------------*

CONSTANTS:
  c_gr   TYPE ekbe-vgabe VALUE '1',
  c_miro TYPE ekbe-vgabe VALUE '2'.

*---------------------------------------------------------------------*
* PO Data
*---------------------------------------------------------------------*

TYPES: BEGIN OF ty_ekpo,
         ebeln TYPE ekko-ebeln,
         lifnr TYPE ekko-lifnr,
         bukrs TYPE ekko-bukrs,
         waers TYPE ekko-waers,
         ebelp TYPE ekpo-ebelp,
         matnr TYPE ekpo-matnr,
         txz01 TYPE ekpo-txz01,
         werks TYPE ekpo-werks,
         menge TYPE ekpo-menge,
         netwr TYPE ekpo-netwr,
       END OF ty_ekpo.

DATA:
  gt_ekpo TYPE STANDARD TABLE OF ty_ekpo,
  gs_ekpo TYPE ty_ekpo.

*---------------------------------------------------------------------*
* Vendor Data
*---------------------------------------------------------------------*

TYPES: BEGIN OF ty_lfa1,
         lifnr TYPE lfa1-lifnr,
         name1 TYPE lfa1-name1,
       END OF ty_lfa1.

DATA:
  gt_lfa1 TYPE STANDARD TABLE OF ty_lfa1,
  gs_lfa1 TYPE ty_lfa1.

*---------------------------------------------------------------------*
* PO History - GR / MIRO
*---------------------------------------------------------------------*

TYPES: BEGIN OF ty_ekbe,
         ebeln TYPE ekbe-ebeln,
         ebelp TYPE ekbe-ebelp,
         vgabe TYPE ekbe-vgabe,
         gjahr TYPE ekbe-gjahr,
         belnr TYPE ekbe-belnr,
         buzei TYPE ekbe-buzei,
         menge TYPE ekbe-menge,
         wrbtr TYPE ekbe-wrbtr,
         shkzg TYPE ekbe-shkzg,
       END OF ty_ekbe.

DATA:
  gt_ekbe TYPE STANDARD TABLE OF ty_ekbe,
  gs_ekbe TYPE ty_ekbe.

*---------------------------------------------------------------------*
* MIRO Documents
*---------------------------------------------------------------------*

TYPES: BEGIN OF ty_inv,
         ebeln TYPE ekbe-ebeln,
         ebelp TYPE ekbe-ebelp,
         bukrs TYPE ekko-bukrs,
         belnr TYPE ekbe-belnr,
         gjahr TYPE ekbe-gjahr,
       END OF ty_inv.

DATA:
  gt_inv TYPE STANDARD TABLE OF ty_inv,
  gs_inv TYPE ty_inv.

*---------------------------------------------------------------------*
* Cleared Vendor Documents
*---------------------------------------------------------------------*

TYPES: BEGIN OF ty_bsak,
         bukrs TYPE bsak-bukrs,
         belnr TYPE bsak-belnr,
         gjahr TYPE bsak-gjahr,
         augbl TYPE bsak-augbl,
       END OF ty_bsak.

DATA:
  gt_bsak TYPE STANDARD TABLE OF ty_bsak,
  gs_bsak TYPE ty_bsak.

*---------------------------------------------------------------------*
* Final Output
*---------------------------------------------------------------------*

TYPES: BEGIN OF ty_output,
         ebeln        TYPE ekko-ebeln,
         ebelp        TYPE ekpo-ebelp,
         lifnr        TYPE ekko-lifnr,
         name1        TYPE lfa1-name1,
         matnr        TYPE ekpo-matnr,
         txz01        TYPE ekpo-txz01,
         werks        TYPE ekpo-werks,
         waers        TYPE ekko-waers,

         po_qty       TYPE ekpo-menge,
         gr_qty       TYPE ekpo-menge,
         balance_qty  TYPE ekpo-menge,
         miro_qty     TYPE ekpo-menge,

         po_value     TYPE ekpo-netwr,
         inv_value    TYPE ekbe-wrbtr,

         gr_status    TYPE char20,
         inv_status   TYPE char20,
         pay_status   TYPE char20,
         overall_stat TYPE char30,

       END OF ty_output.

DATA:
  gt_output TYPE STANDARD TABLE OF ty_output,
  gs_output TYPE ty_output.

*---------------------------------------------------------------------*
* Working Variables
*---------------------------------------------------------------------*

DATA:
  gv_inv_count  TYPE i,
  gv_paid_count TYPE i,
  gv_show       TYPE c LENGTH 1.

*---------------------------------------------------------------------*
* ALV
*---------------------------------------------------------------------*

DATA:
  gt_fieldcat TYPE slis_t_fieldcat_alv,
  gs_fieldcat TYPE slis_fieldcat_alv,
  gs_layout   TYPE slis_layout_alv.

*---------------------------------------------------------------------*
* Chart Data - PO count by overall status
*---------------------------------------------------------------------*

TYPES: BEGIN OF ty_chart,
         status TYPE char30,
         count  TYPE i,
         color  TYPE c LENGTH 7,
       END OF ty_chart.

TYPES: BEGIN OF ty_po_stat,
         ebeln  TYPE ekko-ebeln,
         status TYPE char30,
       END OF ty_po_stat.

TYPES: ty_html_line TYPE c LENGTH 255.

DATA:
  gt_chart    TYPE STANDARD TABLE OF ty_chart,
  gs_chart    TYPE ty_chart,
  gt_html     TYPE STANDARD TABLE OF ty_html_line,
  gs_html     TYPE ty_html_line,
  gv_html_url TYPE c LENGTH 255.

DATA:
  go_dock TYPE REF TO cl_gui_docking_container,
  go_html TYPE REF TO cl_gui_html_viewer.

*---------------------------------------------------------------------*
* START-OF-SELECTION
*---------------------------------------------------------------------*

START-OF-SELECTION.

  PERFORM get_po_data.

  IF gt_ekpo IS INITIAL.
    MESSAGE 'No Purchase Orders found' TYPE 'I'.
    STOP.
  ENDIF.

  PERFORM get_vendor_data.
  PERFORM get_po_history.
  PERFORM get_invoice_documents.
  PERFORM get_payment_data.
  PERFORM build_output.

  IF gt_output IS INITIAL.
    MESSAGE 'No data found for selected status' TYPE 'I'.
    STOP.
  ENDIF.

  PERFORM display_alv.

*---------------------------------------------------------------------*
* Get PO Data
*---------------------------------------------------------------------*

FORM get_po_data.

  SELECT
    a~ebeln
    a~lifnr
    a~bukrs
    a~waers
    b~ebelp
    b~matnr
    b~txz01
    b~werks
    b~menge
    b~netwr
    INTO TABLE gt_ekpo
    FROM ekko AS a
    INNER JOIN ekpo AS b
      ON a~ebeln = b~ebeln
    WHERE a~ebeln IN s_ebeln
      AND a~lifnr IN s_lifnr
      AND a~bukrs IN s_bukrs
      AND b~werks IN s_werks
      AND a~bedat IN s_bedat
      AND b~loekz = space.

ENDFORM.

*---------------------------------------------------------------------*
* Get Vendor Name
*---------------------------------------------------------------------*

FORM get_vendor_data.

  DATA:
    ls_ekpo TYPE ty_ekpo.

  IF gt_ekpo IS INITIAL.
    RETURN.
  ENDIF.

  SELECT lifnr
         name1
    INTO TABLE gt_lfa1
    FROM lfa1
    FOR ALL ENTRIES IN gt_ekpo
    WHERE lifnr = gt_ekpo-lifnr.

  SORT gt_lfa1 BY lifnr.

ENDFORM.

*---------------------------------------------------------------------*
* Get PO History
* VGABE 1 = Goods Receipt
* VGABE 2 = Invoice Receipt / MIRO
*---------------------------------------------------------------------*

FORM get_po_history.

  IF gt_ekpo IS INITIAL.
    RETURN.
  ENDIF.

  SELECT
    ebeln
    ebelp
    vgabe
    gjahr
    belnr
    buzei
    menge
    wrbtr
    shkzg
    INTO TABLE gt_ekbe
    FROM ekbe
    FOR ALL ENTRIES IN gt_ekpo
    WHERE ebeln = gt_ekpo-ebeln
      AND ebelp = gt_ekpo-ebelp
      AND ( vgabe = c_gr
         OR vgabe = c_miro ).

  SORT gt_ekbe BY ebeln ebelp vgabe gjahr belnr buzei.

ENDFORM.

*---------------------------------------------------------------------*
* Get MIRO Documents
*---------------------------------------------------------------------*

FORM get_invoice_documents.

  CLEAR gt_inv.

  LOOP AT gt_ekbe INTO gs_ekbe.

    IF gs_ekbe-vgabe = c_miro.

      CLEAR gs_ekpo.

      READ TABLE gt_ekpo INTO gs_ekpo
        WITH KEY ebeln = gs_ekbe-ebeln
                 ebelp = gs_ekbe-ebelp.

      IF sy-subrc = 0.

        CLEAR gs_inv.

        gs_inv-ebeln = gs_ekbe-ebeln.
        gs_inv-ebelp = gs_ekbe-ebelp.
        gs_inv-bukrs = gs_ekpo-bukrs.
        gs_inv-belnr = gs_ekbe-belnr.
        gs_inv-gjahr = gs_ekbe-gjahr.

        APPEND gs_inv TO gt_inv.

      ENDIF.

    ENDIF.

  ENDLOOP.

  SORT gt_inv BY ebeln ebelp bukrs belnr gjahr.

  DELETE ADJACENT DUPLICATES FROM gt_inv
    COMPARING ebeln ebelp bukrs belnr gjahr.

ENDFORM.

*---------------------------------------------------------------------*
* Get Payment Information
*
* BSAK = Vendor line items which are cleared
*
* If MIRO document exists in BSAK:
*   Invoice has been cleared / paid
*---------------------------------------------------------------------*

FORM get_payment_data.

  CLEAR gt_bsak.

  IF gt_inv IS INITIAL.
    RETURN.
  ENDIF.

  SELECT
    bukrs
    belnr
    gjahr
    augbl
    INTO TABLE gt_bsak
    FROM bsak
    FOR ALL ENTRIES IN gt_inv
    WHERE bukrs = gt_inv-bukrs
      AND belnr = gt_inv-belnr
      AND gjahr = gt_inv-gjahr.

  SORT gt_bsak BY bukrs belnr gjahr.

  DELETE ADJACENT DUPLICATES FROM gt_bsak
    COMPARING bukrs belnr gjahr.

ENDFORM.

*---------------------------------------------------------------------*
* Build Final Output
*---------------------------------------------------------------------*

FORM build_output.

  DATA:
    lv_gr_qty      TYPE ekpo-menge,
    lv_miro_qty    TYPE ekpo-menge,
    lv_inv_value   TYPE ekbe-wrbtr,
    lv_inv_found   TYPE c LENGTH 1,
    lv_paid_found  TYPE c LENGTH 1,
    lv_inv_count   TYPE i,
    lv_paid_count  TYPE i.

  LOOP AT gt_ekpo INTO gs_ekpo.

    CLEAR:
      gs_output,
      lv_gr_qty,
      lv_miro_qty,
      lv_inv_value,
      lv_inv_found,
      lv_paid_found,
      lv_inv_count,
      lv_paid_count.

    gs_output-ebeln = gs_ekpo-ebeln.
    gs_output-ebelp = gs_ekpo-ebelp.
    gs_output-lifnr = gs_ekpo-lifnr.
    gs_output-matnr = gs_ekpo-matnr.
    gs_output-txz01 = gs_ekpo-txz01.
    gs_output-werks = gs_ekpo-werks.
    gs_output-waers = gs_ekpo-waers.
    gs_output-po_qty = gs_ekpo-menge.
    gs_output-po_value = gs_ekpo-netwr.

*---------------------------------------------------------------------*
* Vendor Name
*---------------------------------------------------------------------*

    READ TABLE gt_lfa1 INTO gs_lfa1
      WITH KEY lifnr = gs_ekpo-lifnr
      BINARY SEARCH.

    IF sy-subrc = 0.
      gs_output-name1 = gs_lfa1-name1.
    ENDIF.

*---------------------------------------------------------------------*
* Calculate GR and MIRO
*---------------------------------------------------------------------*

    LOOP AT gt_ekbe INTO gs_ekbe
      WHERE ebeln = gs_ekpo-ebeln
        AND ebelp = gs_ekpo-ebelp.

*---------------------------------------------------------------------*
* Goods Receipt
*---------------------------------------------------------------------*

      IF gs_ekbe-vgabe = c_gr.

        IF gs_ekbe-shkzg = 'H'.
          lv_gr_qty = lv_gr_qty - gs_ekbe-menge.
        ELSE.
          lv_gr_qty = lv_gr_qty + gs_ekbe-menge.
        ENDIF.

      ENDIF.

*---------------------------------------------------------------------*
* MIRO
*---------------------------------------------------------------------*

      IF gs_ekbe-vgabe = c_miro.

        lv_inv_found = 'X'.

        IF gs_ekbe-shkzg = 'H'.

          lv_miro_qty  = lv_miro_qty - gs_ekbe-menge.
          lv_inv_value = lv_inv_value - gs_ekbe-wrbtr.

        ELSE.

          lv_miro_qty  = lv_miro_qty + gs_ekbe-menge.
          lv_inv_value = lv_inv_value + gs_ekbe-wrbtr.

        ENDIF.

      ENDIF.

    ENDLOOP.

    gs_output-gr_qty = lv_gr_qty.
    gs_output-miro_qty = lv_miro_qty.
    gs_output-balance_qty =
      gs_output-po_qty - gs_output-gr_qty.
    gs_output-inv_value = lv_inv_value.

*---------------------------------------------------------------------*
* GR Status
*---------------------------------------------------------------------*

    IF lv_gr_qty <= 0.

      gs_output-gr_status = 'Pending'.

    ELSEIF lv_gr_qty < gs_output-po_qty.

      gs_output-gr_status = 'Partial'.

    ELSE.

      gs_output-gr_status = 'Complete'.

    ENDIF.

*---------------------------------------------------------------------*
* Invoice and Payment Status
*---------------------------------------------------------------------*

    LOOP AT gt_inv INTO gs_inv
      WHERE ebeln = gs_ekpo-ebeln
        AND ebelp = gs_ekpo-ebelp.

      lv_inv_count = lv_inv_count + 1.

      READ TABLE gt_bsak INTO gs_bsak
        WITH KEY bukrs = gs_inv-bukrs
                 belnr = gs_inv-belnr
                 gjahr = gs_inv-gjahr
        BINARY SEARCH.

      IF sy-subrc = 0.
        lv_paid_count = lv_paid_count + 1.
      ENDIF.

    ENDLOOP.

*---------------------------------------------------------------------*
* Invoice Status
*---------------------------------------------------------------------*

    IF lv_inv_count = 0.

      gs_output-inv_status = 'Pending'.

    ELSE.

      gs_output-inv_status = 'Received'.

    ENDIF.

*---------------------------------------------------------------------*
* Payment Status
*---------------------------------------------------------------------*

    IF lv_inv_count = 0.

      gs_output-pay_status = 'Not Applicable'.

    ELSEIF lv_paid_count = lv_inv_count.

      gs_output-pay_status = 'Paid'.

    ELSEIF lv_paid_count > 0.

      gs_output-pay_status = 'Partially Paid'.

    ELSE.

      gs_output-pay_status = 'Not Paid'.

    ENDIF.

*---------------------------------------------------------------------*
* Overall Status
*---------------------------------------------------------------------*

    IF lv_gr_qty <= 0.

      gs_output-overall_stat = 'GR Pending'.

    ELSEIF lv_gr_qty < gs_output-po_qty.

      gs_output-overall_stat = 'Partial GR'.

    ELSEIF lv_inv_count = 0.

      gs_output-overall_stat = 'Invoice Pending'.

    ELSEIF lv_paid_count = lv_inv_count.

      gs_output-overall_stat = 'Paid'.

    ELSEIF lv_paid_count > 0.

      gs_output-overall_stat = 'Partially Paid'.

    ELSE.

      gs_output-overall_stat = 'Invoice Not Paid'.

    ENDIF.

*---------------------------------------------------------------------*
* Selection Status Filter
*---------------------------------------------------------------------*

    CLEAR gv_show.

    IF p_all = 'X'.

      gv_show = 'X'.

    ELSEIF p_paid = 'X'.

      IF gs_output-pay_status = 'Paid'.
        gv_show = 'X'.
      ENDIF.

    ELSEIF p_npay = 'X'.

      IF gs_output-pay_status = 'Not Paid'
         OR gs_output-pay_status = 'Partially Paid'.

        gv_show = 'X'.

      ENDIF.

    ELSEIF p_invp = 'X'.

      IF gs_output-inv_status = 'Pending'.
        gv_show = 'X'.
      ENDIF.

    ELSEIF p_grp = 'X'.

      IF gs_output-gr_status = 'Pending'
         OR gs_output-gr_status = 'Partial'.

        gv_show = 'X'.

      ENDIF.

    ENDIF.

    IF gv_show = 'X'.
      APPEND gs_output TO gt_output.
    ENDIF.

  ENDLOOP.

ENDFORM.

*---------------------------------------------------------------------*
* Add ALV Field
*---------------------------------------------------------------------*

FORM add_fieldcat
  USING
    p_fieldname TYPE slis_fieldcat_alv-fieldname
    p_text      TYPE slis_fieldcat_alv-seltext_m
    p_length    TYPE i
    p_sum       TYPE c.

  CLEAR gs_fieldcat.

  gs_fieldcat-fieldname = p_fieldname.
  gs_fieldcat-seltext_m = p_text.
  gs_fieldcat-outputlen = p_length.

  IF p_sum = 'X'.
    gs_fieldcat-do_sum = 'X'.
  ENDIF.

  APPEND gs_fieldcat TO gt_fieldcat.

ENDFORM.

*---------------------------------------------------------------------*
* Display ALV
*---------------------------------------------------------------------*

FORM display_alv.

  CLEAR gt_fieldcat.

  PERFORM add_fieldcat USING
    'EBELN'
    'PO Number'
    12
    space.

  PERFORM add_fieldcat USING
    'EBELP'
    'Item'
    6
    space.

  PERFORM add_fieldcat USING
    'LIFNR'
    'Vendor'
    12
    space.

  PERFORM add_fieldcat USING
    'NAME1'
    'Vendor Name'
    25
    space.

  PERFORM add_fieldcat USING
    'MATNR'
    'Material'
    18
    space.

  PERFORM add_fieldcat USING
    'TXZ01'
    'Material Description'
    30
    space.

  PERFORM add_fieldcat USING
    'WERKS'
    'Plant'
    8
    space.

  PERFORM add_fieldcat USING
    'WAERS'
    'Currency'
    8
    space.

  PERFORM add_fieldcat USING
    'PO_QTY'
    'PO Qty'
    12
    'X'.

  PERFORM add_fieldcat USING
    'GR_QTY'
    'GR Qty'
    12
    'X'.

  PERFORM add_fieldcat USING
    'BALANCE_QTY'
    'Balance Qty'
    12
    'X'.

  PERFORM add_fieldcat USING
    'MIRO_QTY'
    'MIRO Qty'
    12
    'X'.

  PERFORM add_fieldcat USING
    'PO_VALUE'
    'PO Value'
    15
    'X'.

  PERFORM add_fieldcat USING
    'INV_VALUE'
    'Invoice Value'
    15
    'X'.

  PERFORM add_fieldcat USING
    'GR_STATUS'
    'GR Status'
    15
    space.

  PERFORM add_fieldcat USING
    'INV_STATUS'
    'Invoice Status'
    18
    space.

  PERFORM add_fieldcat USING
    'PAY_STATUS'
    'Payment Status'
    18
    space.

  PERFORM add_fieldcat USING
    'OVERALL_STAT'
    'Overall Status'
    22
    space.

*---------------------------------------------------------------------*
* ALV Layout
*---------------------------------------------------------------------*

  CLEAR gs_layout.

  gs_layout-zebra = 'X'.
  gs_layout-colwidth_optimize = 'X'.

*---------------------------------------------------------------------*
* Display
*---------------------------------------------------------------------*

  PERFORM prepare_chart_data.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program       = sy-repid
      i_callback_pf_status_set = 'SET_PF_STATUS'
      is_layout                = gs_layout
      it_fieldcat              = gt_fieldcat
      i_save                   = 'A'
    TABLES
      t_outtab                 = gt_output
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Error while displaying ALV' TYPE 'I'.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
* Keep standard ALV toolbar and attach the HTML chart
* above the grid on the ALV screen
*---------------------------------------------------------------------*

FORM set_pf_status USING rt_extab TYPE slis_t_extab.

  SET PF-STATUS 'STANDARD_FULLSCREEN' OF PROGRAM 'SAPLSLVC_FULLSCREEN'
    EXCLUDING rt_extab.

  IF sy-batch = 'X'.
    RETURN.
  ENDIF.

  IF go_html IS INITIAL.
    PERFORM show_status_chart.
  ENDIF.

ENDFORM.

*---------------------------------------------------------------------*
* Count unique POs from GT_OUTPUT by overall status
*---------------------------------------------------------------------*

FORM prepare_chart_data.

  DATA:
    lt_po TYPE STANDARD TABLE OF ty_po_stat,
    ls_po TYPE ty_po_stat.

  CLEAR: gt_chart, lt_po, gt_html.

  PERFORM add_chart_row USING 'GR Pending'       '#E74C3C'.
  PERFORM add_chart_row USING 'Partial GR'       '#E67E22'.
  PERFORM add_chart_row USING 'Invoice Pending'  '#F1C40F'.
  PERFORM add_chart_row USING 'Invoice Not Paid' '#9B59B6'.
  PERFORM add_chart_row USING 'Partially Paid'   '#3498DB'.
  PERFORM add_chart_row USING 'Paid'             '#27AE60'.

  LOOP AT gt_output INTO gs_output.
    CLEAR ls_po.
    ls_po-ebeln  = gs_output-ebeln.
    ls_po-status = gs_output-overall_stat.
    APPEND ls_po TO lt_po.
  ENDLOOP.

  SORT lt_po BY ebeln status.
  DELETE ADJACENT DUPLICATES FROM lt_po COMPARING ebeln status.

  LOOP AT lt_po INTO ls_po.

    READ TABLE gt_chart INTO gs_chart
      WITH KEY status = ls_po-status.

    IF sy-subrc = 0.
      gs_chart-count = gs_chart-count + 1.
      MODIFY gt_chart FROM gs_chart INDEX sy-tabix.
    ENDIF.

  ENDLOOP.

  PERFORM build_chart_html.

ENDFORM.

*---------------------------------------------------------------------*
* Initialize one chart category
*---------------------------------------------------------------------*

FORM add_chart_row
  USING
    p_status TYPE char30
    p_color  TYPE c.

  CLEAR gs_chart.
  gs_chart-status = p_status.
  gs_chart-count  = 0.
  gs_chart-color  = p_color.
  APPEND gs_chart TO gt_chart.

ENDFORM.

*---------------------------------------------------------------------*
* Append one HTML line
*---------------------------------------------------------------------*

FORM add_html USING p_text TYPE c.

  CLEAR gs_html.
  gs_html = p_text.
  APPEND gs_html TO gt_html.

ENDFORM.

*---------------------------------------------------------------------*
* Build HTML5 pie + bar chart from GT_CHART
*---------------------------------------------------------------------*

FORM build_chart_html.

  DATA:
    lv_line TYPE c LENGTH 255,
    lv_c1   TYPE c LENGTH 10,
    lv_c2   TYPE c LENGTH 10,
    lv_c3   TYPE c LENGTH 10,
    lv_c4   TYPE c LENGTH 10,
    lv_c5   TYPE c LENGTH 10,
    lv_c6   TYPE c LENGTH 10,
    lv_cnt  TYPE c LENGTH 10.

  CLEAR gt_html.

  READ TABLE gt_chart INTO gs_chart INDEX 1.
  lv_c1 = gs_chart-count.
  CONDENSE lv_c1 NO-GAPS.

  READ TABLE gt_chart INTO gs_chart INDEX 2.
  lv_c2 = gs_chart-count.
  CONDENSE lv_c2 NO-GAPS.

  READ TABLE gt_chart INTO gs_chart INDEX 3.
  lv_c3 = gs_chart-count.
  CONDENSE lv_c3 NO-GAPS.

  READ TABLE gt_chart INTO gs_chart INDEX 4.
  lv_c4 = gs_chart-count.
  CONDENSE lv_c4 NO-GAPS.

  READ TABLE gt_chart INTO gs_chart INDEX 5.
  lv_c5 = gs_chart-count.
  CONDENSE lv_c5 NO-GAPS.

  READ TABLE gt_chart INTO gs_chart INDEX 6.
  lv_c6 = gs_chart-count.
  CONDENSE lv_c6 NO-GAPS.

  PERFORM add_html USING
    '<!DOCTYPE html><html><head>'.
  PERFORM add_html USING
    '<meta http-equiv="X-UA-Compatible" content="IE=edge">'.
  PERFORM add_html USING
    '<meta charset="utf-8">'.
  PERFORM add_html USING
    '<title>PO Status Chart</title>'.
  PERFORM add_html USING
    '<style>'.
  PERFORM add_html USING
    'body{font-family:Arial,sans-serif;margin:6px;background:#f4f4f4;}'.
  PERFORM add_html USING
    'h2{margin:0 0 6px 0;font-size:15px;color:#222;}'.
  PERFORM add_html USING
    'table.wrap td{vertical-align:top;padding:4px 10px;}'.
  PERFORM add_html USING
    '.box{background:#fff;border:1px solid #ccc;padding:6px;}'.
  PERFORM add_html USING
    '.leg td{font-size:11px;padding:1px 5px;}'.
  PERFORM add_html USING
    '.sw{width:12px;height:12px;border:1px solid #666;}'.
  PERFORM add_html USING
    '</style></head><body>'.
  PERFORM add_html USING
    '<h2>Purchase Order Count by Status</h2>'.
  PERFORM add_html USING
    '<table class="wrap"><tr><td class="box">'.
  PERFORM add_html USING
    '<b>Pie Chart</b><br/>'.
  PERFORM add_html USING
    '<canvas id="pie" width="240" height="200"></canvas>'.
  PERFORM add_html USING
    '<table class="leg">'.

  LOOP AT gt_chart INTO gs_chart.
    lv_cnt = gs_chart-count.
    CONDENSE lv_cnt NO-GAPS.
    CONCATENATE
      '<tr><td><div class="sw" style="background:'
      gs_chart-color
      ';"></div></td><td>'
      gs_chart-status
      '</td><td><b>'
      lv_cnt
      '</b></td></tr>'
      INTO lv_line.
    PERFORM add_html USING lv_line.
  ENDLOOP.

  PERFORM add_html USING
    '</table></td><td class="box">'.
  PERFORM add_html USING
    '<b>Bar Chart</b><br/>'.
  PERFORM add_html USING
    '<canvas id="bar" width="460" height="220"></canvas>'.
  PERFORM add_html USING
    '</td></tr></table>'.
  PERFORM add_html USING
    '<script type="text/javascript">'.
  PERFORM add_html USING
    'var labels=["GR Pending","Partial GR","Invoice Pending",'.
  PERFORM add_html USING
    '"Invoice Not Paid","Partially Paid","Paid"];'.
  CONCATENATE
    'var values=['
    lv_c1 ',' lv_c2 ',' lv_c3 ',' lv_c4 ',' lv_c5 ',' lv_c6
    '];'
    INTO lv_line.
  PERFORM add_html USING lv_line.
  PERFORM add_html USING
    'var colors=["#E74C3C","#E67E22","#F1C40F",'.
  PERFORM add_html USING
    '"#9B59B6","#3498DB","#27AE60"];'.
  PERFORM add_html USING
    'function drawPie(){'.
  PERFORM add_html USING
    'var c=document.getElementById("pie");'.
  PERFORM add_html USING
    'if(!c||!c.getContext){return;}'.
  PERFORM add_html USING
    'var ctx=c.getContext("2d");'.
  PERFORM add_html USING
    'var tot=0,i,a,s=-Math.PI/2;'.
  PERFORM add_html USING
    'for(i=0;i<values.length;i++){tot=tot+values[i];}'.
  PERFORM add_html USING
    'var cx=c.width/2,cy=c.height/2,r=Math.min(cx,cy)-8;'.
  PERFORM add_html USING
    'if(tot==0){ctx.beginPath();ctx.arc(cx,cy,r,0,Math.PI*2);'.
  PERFORM add_html USING
    'ctx.fillStyle="#cccccc";ctx.fill();return;}'.
  PERFORM add_html USING
    'for(i=0;i<values.length;i++){'.
  PERFORM add_html USING
    'a=(values[i]/tot)*Math.PI*2;'.
  PERFORM add_html USING
    'ctx.beginPath();ctx.moveTo(cx,cy);'.
  PERFORM add_html USING
    'ctx.arc(cx,cy,r,s,s+a);ctx.closePath();'.
  PERFORM add_html USING
    'ctx.fillStyle=colors[i];ctx.fill();s=s+a;}}'.
  PERFORM add_html USING
    'function drawBar(){'.
  PERFORM add_html USING
    'var c=document.getElementById("bar");'.
  PERFORM add_html USING
    'if(!c||!c.getContext){return;}'.
  PERFORM add_html USING
    'var ctx=c.getContext("2d");'.
  PERFORM add_html USING
    'var max=0,i,bh,x,y,barW,gap;'.
  PERFORM add_html USING
    'for(i=0;i<values.length;i++){'.
  PERFORM add_html USING
    'if(values[i]>max){max=values[i];}}'.
  PERFORM add_html USING
    'if(max==0){max=1;}'.
  PERFORM add_html USING
    'var pL=28,pB=70,pT=18,pR=10;'.
  PERFORM add_html USING
    'var w=c.width-pL-pR,h=c.height-pT-pB;'.
  PERFORM add_html USING
    'gap=w/values.length;barW=gap*0.55;'.
  PERFORM add_html USING
    'ctx.strokeStyle="#333";ctx.beginPath();'.
  PERFORM add_html USING
    'ctx.moveTo(pL,pT);ctx.lineTo(pL,pT+h);'.
  PERFORM add_html USING
    'ctx.lineTo(pL+w,pT+h);ctx.stroke();'.
  PERFORM add_html USING
    'for(i=0;i<values.length;i++){'.
  PERFORM add_html USING
    'bh=(values[i]/max)*h;'.
  PERFORM add_html USING
    'x=pL+gap*i+(gap-barW)/2;y=pT+h-bh;'.
  PERFORM add_html USING
    'ctx.fillStyle=colors[i];ctx.fillRect(x,y,barW,bh);'.
  PERFORM add_html USING
    'ctx.fillStyle="#000";ctx.font="11px Arial";'.
  PERFORM add_html USING
    'ctx.textAlign="center";'.
  PERFORM add_html USING
    'ctx.fillText(values[i],x+barW/2,y-3);'.
  PERFORM add_html USING
    'ctx.save();ctx.translate(x+barW/2,pT+h+8);'.
  PERFORM add_html USING
    'ctx.rotate(-0.7);ctx.textAlign="right";'.
  PERFORM add_html USING
    'ctx.fillText(labels[i],0,0);ctx.restore();}}'.
  PERFORM add_html USING
    'drawPie();drawBar();'.
  PERFORM add_html USING
    '</script></body></html>'.

ENDFORM.

*---------------------------------------------------------------------*
* Show HTML5 chart in a docking container above the ALV
*---------------------------------------------------------------------*

FORM show_status_chart.

  DATA:
    lv_url TYPE c LENGTH 255.

  CREATE OBJECT go_dock
    EXPORTING
      parent    = cl_gui_container=>screen0
      side      = cl_gui_docking_container=>dock_at_top
      extension = 340
    EXCEPTIONS
      cntl_error                  = 1
      cntl_system_error           = 2
      create_error                = 3
      lifetime_error              = 4
      lifetime_dynpro_dynpro_link = 5
      OTHERS                      = 6.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  CREATE OBJECT go_html
    EXPORTING
      parent = go_dock
    EXCEPTIONS
      cntl_error        = 1
      cntl_install_error = 2
      dp_install_error  = 3
      dp_error          = 4
      OTHERS            = 5.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  CALL METHOD go_html->load_data
    EXPORTING
      type                 = 'text'
      subtype              = 'html'
    IMPORTING
      assigned_url         = lv_url
    CHANGING
      data_table           = gt_html
    EXCEPTIONS
      dp_invalid_parameter = 1
      dp_error_general     = 2
      cntl_error           = 3
      OTHERS               = 4.

  IF sy-subrc <> 0.
    RETURN.
  ENDIF.

  gv_html_url = lv_url.

  CALL METHOD go_html->show_url
    EXPORTING
      url                    = gv_html_url
    EXCEPTIONS
      cntl_error             = 1
      cnht_error_not_allowed = 2
      cnht_error_parameter   = 3
      dp_error_general       = 4
      OTHERS                 = 5.

ENDFORM.
