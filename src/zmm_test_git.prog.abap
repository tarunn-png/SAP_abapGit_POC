*&---------------------------------------------------------------------*
*& Report ZMM_TEST_GIT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT ZMM_TEST_GIT.

PARAMETERS: p_input TYPE char20 DEFAULT 'User'.

START-OF-SELECTION.
  WRITE: / '--- Enhanced Output ---'.
  WRITE: / 'Input parameter:', p_input.
  WRITE: / 'test message from ECC'.
