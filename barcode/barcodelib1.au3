;; L=0 G=1 R=2
Local $EAN13_patterns[10][12] = [ [0,0,0,0,0,0, 2,2,2,2,2,2], _
                                  [0,0,1,0,1,1, 2,2,2,2,2,2], _
                                  [0,0,1,1,0,1, 2,2,2,2,2,2], _
                                  [0,0,1,1,1,0, 2,2,2,2,2,2], _
                                  [0,1,0,0,1,1, 2,2,2,2,2,2], _
                                  [0,1,1,0,0,1, 2,2,2,2,2,2], _
                                  [0,1,1,1,0,0, 2,2,2,2,2,2], _
                                  [0,1,0,1,0,1, 2,2,2,2,2,2], _
                                  [0,1,0,1,1,0, 2,2,2,2,2,2], _
                                  [0,1,1,0,1,0, 2,2,2,2,2,2] ]

Local $LGR_codes[10][3][7] = [ [ [0,0,0,1,1,0,1], [0,1,0,0,1,1,1], [1,1,1,0,0,1,0] ], _
                               [ [0,0,1,1,0,0,1], [0,1,1,0,0,1,1], [1,1,0,0,1,1,0] ], _
                               [ [0,0,1,0,0,1,1], [0,0,1,1,0,1,1], [1,1,0,1,1,0,0] ], _
                               [ [0,1,1,1,1,0,1], [0,1,0,0,0,0,1], [1,0,0,0,0,1,0] ], _
                               [ [0,1,0,0,0,1,1], [0,0,1,1,1,0,1], [1,0,1,1,1,0,0] ], _
                               [ [0,1,1,0,0,0,1], [0,1,1,1,0,0,1], [1,0,0,1,1,1,0] ], _
                               [ [0,1,0,1,1,1,1], [0,0,0,0,1,0,1], [1,0,1,0,0,0,0] ], _
                               [ [0,1,1,1,0,1,1], [0,0,1,0,0,0,1], [1,0,0,0,1,0,0] ], _
                               [ [0,1,1,0,1,1,1], [0,0,0,1,0,0,1], [1,0,0,1,0,0,0] ], _
                               [ [0,0,0,1,0,1,1], [0,0,1,0,1,1,1], [1,1,1,0,1,0,0] ] ]


Func EAN13_Validate($barcodeString)
    Return StringRegExp($barcodeString, '^[0-9]{13}$', 0)
EndFunc


Func EAN13_GetBinCode($barcodeString)
    $numbers = StringSplit($barcodeString, "", 2)
    
    Local $scheme = $numbers[0]
    Local $binArr[95][2] ; [1==bar][1==short_bar]
    Local $controlbins = [0,1,2,45,46,47,48,49,92,93,94]

    Local $bar = 1
    For $i in $controlbins
        $binArr[$i][0] = $bar
        $binArr[$i][1] = 0
        $bar = $bar == 1 ? 0 : 1
    Next
    
    Local $position = 3
        
    For $i = 1 To 6
        For $j = 0 To 6
            $binArr[$position][0] = $LGR_codes[$numbers[$i]] [$EAN13_patterns[$scheme][$i-1]] [$j]
            $binArr[$position][1] = 1
            $position += 1
        Next
    Next
    
    $position = 50
    
    For $i = 7 To 12
        For $j = 0 To 6
            $binArr[$position][0] = $LGR_codes[$numbers[$i]] [$EAN13_patterns[$scheme][$i-1]] [$j]
            $binArr[$position][1] = 1
            $position += 1
        Next
    Next
    
    Return $binArr
EndFunc


Func EAN13_GenBitmap($barcodeString, $hGUI, $top, $left, $width, $height)
    Local $binarr = EAN13_GetBinCode($barcodeString)
    
    local $shrinkpixels = 8
    local $gap1 = 5 ; gap for the first number
    local $scale = $width/(95+$gap1) ; 95 (barcode areas) + gap
    Local $fontsize = 8*$scale
    
    ; init GDI+ objects
    $hGraphic = _GDIPlus_GraphicsCreateFromHWND($hGUI)
    $hBmp = _GDIPlus_BitmapCreateFromGraphics($width, $height, $hGraphic)
    $hImg = _GDIPlus_ImageGetGraphicsContext($hBmp)
    
    Local $hBrush = _GDIPlus_BrushCreateSolid(0xFF000000)
    
    Local $hFamily = _GDIPlus_FontFamilyCreate("Arial")
    Local $hFont = _GDIPlus_FontCreate($hFamily, $fontsize, 0, 2)
    Local $hFormat = _GDIPlus_StringFormatCreate()
    
   _GDIPlus_GraphicsClear($hImg, 0xFFffffff)
    
    ;draw bars
    For $i = 0 To 94
        If $binarr[$i][0] == 1 Then
            _GDIPlus_GraphicsFillRect($hImg, ($gap1+$i)*$scale, 0, 1*$scale, $height-$shrinkpixels*$binarr[$i][1]*$scale, $hBrush)
        EndIF
    Next
    
    ; draw numbers under bars
    Local $shift = [(-$gap1-1), 3, 10, 17, 24, 31, 38, 50, 57, 64, 71, 78, 85]
    Local $numbers = StringSplit($barcodeString, "", 2)
    
    For $i = 0 To 12
        _GDIPlus_GraphicsDrawStringEx($hImg, $numbers[$i], $hFont, _GDIPlus_RectFCreate(($gap1+$shift[$i])*$scale, $height-$shrinkpixels*$scale, $fontsize, $fontsize), $hFormat, $hBrush)
    Next
    
    ; draw
    _GDIPlus_GraphicsDrawImage($hGraphic, $hBmp, $top, $left)
    
    ; cleanup
    _GDIPlus_StringFormatDispose($hFormat)
    _GDIPlus_FontDispose($hFont)
    _GDIPlus_FontFamilyDispose($hFamily)
    
    _GDIPlus_BrushDispose($hBrush)
    
    _GDIPlus_GraphicsDispose($hImg)
    _GDIPlus_GraphicsDispose($hGraphic)
    
    Return $hBmp
EndFunc


