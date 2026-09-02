*&---------------------------------------------------------------------*
*& Report ZSD_ABAPGIT_DEMO_ALV
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZSD_ABAPGIT_DEMO_ALV.

*&---------------------------------------------------------------------*
*& Purpose : Top 10 Customers by Sales Value (NETWR)
*&           - Reads VBAK / VBAP based on the selection screen
*&           - Totals NETWR customer-wise (KUNNR)
*&           - Keeps only the Top 10 customers
*&           - Shows the result as a Pie Chart and in an ALV table
*& Release : Compatible with SAP ECC 6.0 (classic ABAP syntax only)
*&---------------------------------------------------------------------*

TABLES: vbak, vbap.

TYPE-POOLS: slis.                                  " Types for classic ALV

*----------------------------------------------------------------------*
* Global Declarations
*----------------------------------------------------------------------*
* Raw data read from VBAK / VBAP
DATA: BEGIN OF gs_sales,
        kunnr TYPE vbak-kunnr,
        netwr TYPE vbap-netwr,
        waerk TYPE vbak-waerk,
      END OF gs_sales.

DATA: gt_sales LIKE STANDARD TABLE OF gs_sales.

* Customer-wise totals (result table shown in ALV)
DATA: BEGIN OF gs_top,
        kunnr TYPE kna1-kunnr,                     " Customer number
        name1 TYPE kna1-name1,                     " Customer name
        netwr TYPE vbap-netwr,                     " Total sales value
        waerk TYPE vbak-waerk,                     " Currency
      END OF gs_top.

DATA: gt_top LIKE STANDARD TABLE OF gs_top.

* Tables required by the Business Graphics function module
* First field = text (customer), following fields = values
DATA: BEGIN OF gs_graph,
        name(30) TYPE c,                           " Customer text
        value    TYPE i,                           " Total sales value
      END OF gs_graph.

DATA: gt_graph LIKE STANDARD TABLE OF gs_graph.

DATA: BEGIN OF gs_opts,
        option(80) TYPE c,                         " One graphic option per row
      END OF gs_opts.

DATA: gt_opts LIKE STANDARD TABLE OF gs_opts.

* ALV declarations
DATA: gt_fcat   TYPE slis_t_fieldcat_alv,
      gs_fcat   TYPE slis_fieldcat_alv,
      gs_layout TYPE slis_layout_alv.

CONSTANTS: gc_top TYPE i VALUE 10.                 " Number of customers wanted

*----------------------------------------------------------------------*
* Selection Screen (unchanged criteria)
*----------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-001.
  SELECT-OPTIONS: s_vbeln FOR vbak-vbeln,          " Sales Document
                  s_erdat FOR vbak-erdat,          " Created On
                  s_auart FOR vbak-auart,          " Sales Document Type
                  s_matnr FOR vbap-matnr.          " Material Number
SELECTION-SCREEN END OF BLOCK b1.

*----------------------------------------------------------------------*
* Program Flow
*----------------------------------------------------------------------*
START-OF-SELECTION.

  PERFORM get_data.                " 1. Read VBAK / VBAP with selection filters
  PERFORM build_top_customers.     " 2. Total per customer, sort, keep Top 10
  PERFORM get_customer_names.      " 3. Read customer names from KNA1
  PERFORM display_pie_chart.       " 4. Show pie chart
  PERFORM display_alv.             " 5. Show Top 10 details in ALV

*&---------------------------------------------------------------------*
*& Form GET_DATA
*&---------------------------------------------------------------------*
*& Reads the sales data. Only the fields needed for the calculation
*& are selected. All selection screen filters are applied here, so the
*& totals always respect the user's selection.
*&---------------------------------------------------------------------*
FORM get_data.

  SELECT a~kunnr b~netwr a~waerk
    INTO CORRESPONDING FIELDS OF TABLE gt_sales
    FROM vbak AS a
    INNER JOIN vbap AS b ON b~vbeln = a~vbeln
   WHERE a~vbeln IN s_vbeln
     AND a~erdat IN s_erdat
     AND a~auart IN s_auart
     AND b~matnr IN s_matnr.

  IF gt_sales IS INITIAL.
    MESSAGE 'No records found for the selected criteria.'
            TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.

ENDFORM.                    "get_data

*&---------------------------------------------------------------------*
*& Form BUILD_TOP_CUSTOMERS
*&---------------------------------------------------------------------*
*& Aggregation logic:
*&  - COLLECT adds up NETWR for each customer (KUNNR)
*&  - SORT ... DESCENDING puts the highest value on top
*&  - Records after position 10 are deleted -> Top 10 customers
*&---------------------------------------------------------------------*
FORM build_top_customers.

  DATA: lv_index TYPE i.

  LOOP AT gt_sales INTO gs_sales.
    CLEAR gs_top.
    gs_top-kunnr = gs_sales-kunnr.
    gs_top-netwr = gs_sales-netwr.
    gs_top-waerk = gs_sales-waerk.
    COLLECT gs_top INTO gt_top.    " Sums NETWR per customer
  ENDLOOP.

  " Highest sales value first
  SORT gt_top BY netwr DESCENDING.

  " Keep only the first 10 rows
  lv_index = gc_top + 1.
  IF lines( gt_top ) > gc_top.
    DELETE gt_top FROM lv_index.
  ENDIF.

ENDFORM.                    "build_top_customers

*&---------------------------------------------------------------------*
*& Form GET_CUSTOMER_NAMES
*&---------------------------------------------------------------------*
*& Reads the customer name (KNA1-NAME1) for the Top 10 customers only.
*&---------------------------------------------------------------------*
FORM get_customer_names.

  DATA: BEGIN OF ls_kna1,
          kunnr TYPE kna1-kunnr,
          name1 TYPE kna1-name1,
        END OF ls_kna1.

  DATA: lt_kna1 LIKE STANDARD TABLE OF ls_kna1.

  IF gt_top IS INITIAL.
    EXIT.
  ENDIF.

  SELECT kunnr name1
    INTO CORRESPONDING FIELDS OF TABLE lt_kna1
    FROM kna1
    FOR ALL ENTRIES IN gt_top
   WHERE kunnr = gt_top-kunnr.

  SORT lt_kna1 BY kunnr.

  LOOP AT gt_top INTO gs_top.
    READ TABLE lt_kna1 INTO ls_kna1
         WITH KEY kunnr = gs_top-kunnr BINARY SEARCH.
    IF sy-subrc = 0.
      gs_top-name1 = ls_kna1-name1.
      MODIFY gt_top FROM gs_top INDEX sy-tabix TRANSPORTING name1.
    ENDIF.
  ENDLOOP.

ENDFORM.                    "get_customer_names

*&---------------------------------------------------------------------*
*& Form DISPLAY_PIE_CHART
*&---------------------------------------------------------------------*
*& Uses the classic SAP Business Graphics function module
*& GRAPH_MATRIX_3D. The options table controls the chart type:
*&   P2TYPE = PI  -> 2D presentation is a Pie chart
*&   FIFRST = 2D  -> Pie chart (2D view) is shown first
*&---------------------------------------------------------------------*
FORM display_pie_chart.

  CLEAR: gt_graph, gt_opts.

  " Prepare chart data: customer text + rounded sales value
  LOOP AT gt_top INTO gs_top.
    CLEAR gs_graph.
    CONCATENATE gs_top-kunnr gs_top-name1 INTO gs_graph-name
                SEPARATED BY space.
    gs_graph-value = gs_top-netwr.      " Rounded to whole units
    APPEND gs_graph TO gt_graph.
  ENDLOOP.

  " Chart options
  gs_opts-option = 'P2TYPE = PI'.       " 2D chart type = Pie
  APPEND gs_opts TO gt_opts.
  gs_opts-option = 'FIFRST = 2D'.       " Start with the 2D (pie) view
  APPEND gs_opts TO gt_opts.

  CALL FUNCTION 'GRAPH_MATRIX_3D'
    EXPORTING
      col1 = 'Sales Value'
      titl = 'Top 10 Customers by Sales Value'
    TABLES
      data = gt_graph
      opts = gt_opts
    EXCEPTIONS
      OTHERS = 1.

  IF sy-subrc <> 0.
    MESSAGE 'Pie chart could not be displayed.' TYPE 'S' DISPLAY LIKE 'W'.
  ENDIF.

ENDFORM.                    "display_pie_chart

*&---------------------------------------------------------------------*
*& Form DISPLAY_ALV
*&---------------------------------------------------------------------*
*& Builds the field catalog and shows the Top 10 customers in a
*& classic ALV grid (REUSE_ALV_GRID_DISPLAY).
*&---------------------------------------------------------------------*
FORM display_alv.

  CLEAR gt_fcat.

  PERFORM add_field USING 'KUNNR' 'Customer'      space   space.
  PERFORM add_field USING 'NAME1' 'Customer Name' space   space.
  PERFORM add_field USING 'NETWR' 'Total Sales'   'WAERK' 'X'.
  PERFORM add_field USING 'WAERK' 'Currency'      space   space.

  gs_layout-zebra             = 'X'.
  gs_layout-colwidth_optimize = 'X'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY'
    EXPORTING
      i_callback_program = sy-repid
      is_layout          = gs_layout
      it_fieldcat        = gt_fcat
    TABLES
      t_outtab           = gt_top
    EXCEPTIONS
      program_error      = 1
      OTHERS             = 2.

  IF sy-subrc <> 0.
    MESSAGE 'Error while displaying ALV.' TYPE 'S' DISPLAY LIKE 'E'.
  ENDIF.

ENDFORM.                    "display_alv

*&---------------------------------------------------------------------*
*& Form ADD_FIELD
*&---------------------------------------------------------------------*
*& Small helper form that appends one column to the field catalog.
*&---------------------------------------------------------------------*
FORM add_field USING iv_field    TYPE c
                     iv_text     TYPE c
                     iv_currency TYPE c
                     iv_sum      TYPE c.

  CLEAR gs_fcat.
  gs_fcat-fieldname = iv_field.
  gs_fcat-seltext_l = iv_text.
  gs_fcat-seltext_m = iv_text.
  gs_fcat-seltext_s = iv_text.
  gs_fcat-reptext_ddic = iv_text.

  IF iv_currency <> space.
    gs_fcat-cfieldname = iv_currency.       " Currency reference field
  ENDIF.

  IF iv_sum = 'X'.
    gs_fcat-do_sum = 'X'.                   " Show total in ALV
  ENDIF.

  APPEND gs_fcat TO gt_fcat.

ENDFORM.                    "add_field
