AutoItSetOption("GUIOnEventMode", 1)

#include <GDIPlus.au3>
#include <GUIConstantsEx.au3>
#include <WindowsConstants.au3>
#include <WinAPI.au3>
#include <EditConstants.au3>

#Include "barcodelib1.au3"

Global $hGUI, $hBarcodeInputLabel, $hBarcodeInput, $hBarcodeCount, $hBarcodeBitmap, $hBarcodeSaveToFile
Global $hGraphic, $hBmp, $hImg

Main()


Func Main()
    $hGUI = GUICreate("Barcodder", 400, 400)
    GUISetOnEvent($GUI_EVENT_CLOSE, "EV_Exit")
    GUIRegisterMsg($WM_COMMAND, "EV_WM_COMMAND")
    
    $hBarcodeInputLabel = GUICtrlCreateLabel("EAN13 code:", 10, 10, 390, 15)
    $hBarcodeInput = GUICtrlCreateInput("", 10, 30, 120, 20)
    $hBarcodeCount = GUICtrlCreateLabel("0/13", 140, 30, 40, 20)
    $hBarcodeSaveToFile = GUICtrlCreateButton("Save to file", 10, 55, 80, 24)
    GUICtrlSetState($hBarcodeSaveToFile, $GUI_DISABLE)
    GUICtrlSetOnEvent($hBarcodeSaveToFile, "BarcodeSaveToFile")
    
    GUISetState(@SW_SHOW)
    _GDIPlus_Startup()
    
    While 1
        Sleep(100)
    WEnd
EndFunc


Func EV_Exit()
    _GDIPlus_BitmapDispose($hBarcodeBitmap)
    _GDIPlus_Shutdown()
    GUIDelete($hGUI)
    Exit
EndFunc


Func BarcodeSaveToFile()
    $text = GUICtrlRead($hBarcodeInput)
    _GDIPlus_ImageSaveToFile($hBarcodeBitmap, _
                             @ScriptDir & "\barcode_EAN13_" & $text & ".png")
EndFunc


Func GenerateBarcode()
    $text = GUICtrlRead($hBarcodeInput)
    
    If EAN13_Validate($text) Then 
        $hBarcodeBitmap = EAN13_GenBitmap($text, $hGUI, 25, 150, 350, 150)
        GUICtrlSetState($hBarcodeSaveToFile, $GUI_ENABLE)
    Else
        GUICtrlSetState($hBarcodeSaveToFile, $GUI_DISABLE)
        _GDIPlus_GraphicsClear($hBmp)
        _WinAPI_RedrawWindow($hGUI)
    EndIf    

EndFunc


Func EV_WM_COMMAND($hWHnd, $iMsg, $wParam, $lParam)

    If _WinAPI_HiWord($wParam) = $EN_CHANGE And _WinAPI_LoWord($wParam) = $hBarcodeInput Then
        
        $text = GUICtrlRead($hBarcodeInput)
        
        $text = StringRegExpReplace($text, "[^0-9]", "")
        
        GUICtrlSetData($hBarcodeInput, $text)
        GUICtrlSetData($hBarcodeCount, StringLen($text) & "/13")
        GenerateBarcode()
    EndIf
EndFunc
