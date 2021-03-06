VERSION 5.00
Begin VB.Form Form1 
   Caption         =   "Form1"
   ClientHeight    =   8415
   ClientLeft      =   60
   ClientTop       =   345
   ClientWidth     =   12780
   LinkTopic       =   "Form1"
   ScaleHeight     =   8415
   ScaleWidth      =   12780
   StartUpPosition =   3  'Windows Default
   Begin VB.CommandButton Command1 
      Caption         =   "ByteArray Test"
      Height          =   285
      Left            =   4365
      TabIndex        =   6
      Top             =   0
      Width           =   1770
   End
   Begin VB.CommandButton cmdFile 
      Caption         =   "File Test"
      Height          =   285
      Left            =   3195
      TabIndex        =   5
      Top             =   0
      Width           =   960
   End
   Begin VB.ListBox List1 
      Height          =   2010
      Left            =   135
      TabIndex        =   4
      Top             =   6165
      Width           =   12525
   End
   Begin VB.TextBox txtDecomp 
      BeginProperty Font 
         Name            =   "Courier New"
         Size            =   8.25
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   5685
      Left            =   6480
      MultiLine       =   -1  'True
      ScrollBars      =   2  'Vertical
      TabIndex        =   1
      Top             =   360
      Width           =   6225
   End
   Begin VB.TextBox txtCompressed 
      BeginProperty Font 
         Name            =   "Courier New"
         Size            =   8.25
         Charset         =   0
         Weight          =   400
         Underline       =   0   'False
         Italic          =   0   'False
         Strikethrough   =   0   'False
      EndProperty
      Height          =   5685
      Left            =   90
      MultiLine       =   -1  'True
      ScrollBars      =   2  'Vertical
      TabIndex        =   0
      Top             =   315
      Width           =   6225
   End
   Begin VB.Label Label2 
      Caption         =   "Decompressed"
      Height          =   240
      Left            =   6525
      TabIndex        =   3
      Top             =   45
      Width           =   1140
   End
   Begin VB.Label Label1 
      Caption         =   "Compressed"
      Height          =   240
      Left            =   135
      TabIndex        =   2
      Top             =   45
      Width           =   1140
   End
End
Attribute VB_Name = "Form1"
Attribute VB_GlobalNameSpace = False
Attribute VB_Creatable = False
Attribute VB_PredeclaredId = True
Attribute VB_Exposed = False
'note if you hit stop in the ide without closing the form, you probably
'wont be able to recompile the dll without closing out the ide.
'thats what the freelibrary call in form_unload is for..
'
'the same dll can actually operate on either byte arrays or strings
'its just in how you define the declare..I have included both examples below
'
Dim hLib As Long
Private Declare Function FreeLibrary Lib "kernel32" (ByVal hLibModule As Long) As Long
Private Declare Function LoadLibrary Lib "kernel32" Alias "LoadLibraryA" (ByVal lpLibFileName As String) As Long

Private startTime As Long
Private Declare Function GetTickCount Lib "kernel32" () As Long

Enum eMsg
    em_version = 0
    em_lastErr = 1
End Enum
    
Private Declare Function LZOGetMsg Lib "minilzo.dll" ( _
            ByVal buf As String, _
            ByVal sz As Long, _
            Optional ByVal msgid As eMsg = em_version _
        ) As Long


Private Declare Function Compress Lib "minilzo.dll" ( _
            ByVal bufIn As String, _
            ByVal inSz As Long, _
            ByVal bufOut As String, _
            ByVal outSz As Long _
        ) As Long

Private Declare Function DeCompress Lib "minilzo.dll" ( _
            ByVal bufIn As String, _
            ByVal inSz As Long, _
            ByVal bufOut As String, _
            ByVal outSz As Long _
        ) As Long


'-----------------------------[ redefined declare for byte arrays ]----------------------
Private Declare Function CompressByteArray Lib "minilzo.dll" Alias "Compress" ( _
            ByVal bufIn As Long, _
            ByVal inSz As Long, _
            ByVal bufOut As Long, _
            ByVal outSz As Long _
        ) As Long

Private Declare Function DeCompressByteArray Lib "minilzo.dll" Alias "DeCompress" ( _
            ByVal bufIn As Long, _
            ByVal inSz As Long, _
            ByVal bufOut As Long, _
            ByVal outSz As Long _
        ) As Long




Private Sub cmdFile_Click()
    
    Dim f As String
    Dim comp As String
    Dim decomp As String
    
    f = App.path & "\minilzo.dll"
    If Not FileExists(f) Then
        MsgBox "dll not found"
        Exit Sub
    End If
    
    List1.Clear
    
    f = ReadFile(f)
    List1.AddItem "Loading file: minilzo.dll  size: " & Len(f)
    
    StartBenchMark
    If Not LZO(f, comp) Then Exit Sub
    List1.AddItem Len(f) & " bytes compressed down to " & Len(comp) & EndBenchMark
    txtCompressed = hexdump(comp)
    
    StartBenchMark
    If Not LZO(comp, decomp, Len(f)) Then Exit Sub
    List1.AddItem "Decompressed size is now " & Len(decomp) & EndBenchMark
    txtDecomp = hexdump(decomp)
    
    If decomp = f Then
        List1.AddItem "File data matches before and after!"
    Else
        List1.AddItem "FAIL! - len(org) = " & Len(f) & " len(decomp) = " & Len(decomp)
    End If
    
End Sub

Private Sub Command1_Click()
    
    Dim f As String
    Dim comp As String
    Dim decomp As String
    Dim b() As Byte
    Dim bComp() As Byte
    Dim bDeComp() As Byte
    Dim orgSize As Long
    
    Dim fh As Long
    
    f = App.path & "\minilzo.dll"
    If Not FileExists(f) Then
        MsgBox "dll not found"
        Exit Sub
    End If
    
    List1.Clear
    List1.AddItem "Starting byte array test..."
    
    fh = FreeFile
    Open f For Binary As fh
    ReDim b(LOF(fh))
    Get fh, , b()
    Close fh
    
    orgSize = UBound(b)
    List1.AddItem "Loading file: minilzo.dll  size: " & orgSize
    
    StartBenchMark
    If Not bLZO(b, bComp) Then Exit Sub
    List1.AddItem orgSize & " bytes compressed down to " & UBound(bComp) & EndBenchMark
    txtCompressed = hexdump(StrConv(bComp, vbUnicode))
    
    StartBenchMark
    If Not bLZO(bComp, bDeComp, orgSize) Then Exit Sub
    List1.AddItem "Decompressed size is now " & UBound(bDeComp) & EndBenchMark
    txtDecomp = hexdump(StrConv(bDeComp, vbUnicode))
    
    Dim failed As Boolean
    
    For i = 0 To UBound(b)
        If i > UBound(bDeComp) Then
            failed = True
            Exit For
        End If
        If b(i) <> bDeComp(i) Then
            failed = True
            Exit For
        End If
    Next
    
    If Not failed Then
        List1.AddItem "File data matches before and after!"
    Else
        List1.AddItem "FAIL! - len(org) = " & orgSize & " len(decomp) = " & UBound(bDeComp)
    End If
    
End Sub


'run the string test...
Private Sub Form_Load()

    hLib = LoadLibrary("minilzo.dll")
    If hLib = 0 Then hLib = LoadLibrary(App.path & "\minilzo.dll")
    If hLib = 0 Then hLib = LoadLibrary(App.path & "\..\minilzo.dll")
    If hLib = 0 Then hLib = LoadLibrary(App.path & "\..\..\minilzo.dll")
    
    If hLib = 0 Then
        MsgBox "We could not find the dll? or its corrupt?"
        End
    End If
    
    List1.AddItem "minilzo.dll found.."
    List1.AddItem LZOMsg(em_version)
    
    Dim a As String
    Dim compressed As String
    Dim decompressed As String
    
    a = String(100000, "A") '100kb
    StartBenchMark
    If Not LZO(a, compressed) Then Exit Sub
    List1.AddItem Len(a) & " bytes compressed down to " & Len(compressed) & EndBenchMark
    txtCompressed = hexdump(compressed)
        
    List1.AddItem "Trying to decompress with to small a buffer!"
    StartBenchMark
    If Not LZO(compressed, decompressed, Len(compressed) + 1) Then
        List1.AddItem "decompress failed but did not crash " & EndBenchMark
    End If
        
    List1.AddItem "Now trying to decompress properly.."
    StartBenchMark
    If Not LZO(compressed, decompressed, Len(a)) Then Exit Sub
    List1.AddItem "Decompressed size is now " & Len(decompressed) & EndBenchMark
    txtDecomp = hexdump(decompressed)
    
    If decompressed = a Then
        List1.AddItem "Success original and decompressed strings match!"
    Else
        List1.AddItem "FAIL! - len(org) = " & Len(a) & " len(decomp) = " & Len(decompressed)
    End If

End Sub

Private Sub Form_Unload(Cancel As Integer)
    'so the ide doesnt hang onto it and we can recompile..
    If hLib <> 0 Then FreeLibrary hLib
End Sub

'for decompression, it would probably be better to pass in the original size to get an idea
'of the buffer size to allocate. in practice I would include a header in comporessed data
'that included original size and original md5
'
'note: passing in orgSize tells it you want to decompress the data..
Function LZO(buf As String, ByRef retVal As String, Optional orgSize As Long = 0) As Boolean
    
    Dim bOut As String
    Dim inSz As Long
    Dim outlen As Long
    
    '/* We want to compress the data block at 'in' with length 'IN_LEN' to
    '* the block at 'out'. Because the input block may be incompressible,
    '* we must provide a little more output space in case that compression
    '* is not possible.
    '*/
    
    inSz = Len(buf)
    If orgSize = 0 Then
        outlen = inSz * 2
    Else
        outlen = orgSize * 2
    End If
    
    bOut = String(outlen, Chr(0))
    
    If orgSize = 0 Then
        sz = Compress(buf, inSz, bOut, outlen)
    Else
        sz = DeCompress(buf, inSz, bOut, outlen)
    End If
    
    If sz < 1 Then
        List1.AddItem IIf(orgSize <> 0, "De", "") & "Compression failed: " & LZOMsg()
        Exit Function
    End If
    
    retVal = Mid(bOut, 1, sz)
    LZO = True
        
End Function

Function LZOMsg(Optional m As eMsg = em_lastErr)
    Dim ver As String
    Dim sz As Long
    
    ver = String(500, Chr(0))
    sz = LZOGetMsg(ver, Len(ver), m)
    If sz > 0 Then
        ver = Mid(ver, 1, sz)
        LZOMsg = ver
    End If
    
End Function


Function bLZO(buf() As Byte, ByRef bOut() As Byte, Optional orgSize As Long = 0) As Boolean
    
    Dim inSz As Long
    Dim outlen As Long

    inSz = UBound(buf)
    If orgSize = 0 Then
        outlen = inSz * 2
    Else
        outlen = orgSize * 2
    End If
    
    ReDim bOut(outlen)
    
    If orgSize = 0 Then
        sz = CompressByteArray(VarPtr(buf(0)), inSz, VarPtr(bOut(0)), outlen)
    Else
        sz = DeCompressByteArray(VarPtr(buf(0)), inSz, VarPtr(bOut(0)), outlen)
    End If
    
    If sz < 1 Then
        List1.AddItem IIf(orgSize <> 0, "De", "") & "Compression failed: " & LZOMsg()
        Exit Function
    End If
    
    ReDim Preserve bOut(sz)
    bLZO = True
        
End Function





Function hexdump(it)
    Dim my, i, c, s, a, b
    Dim lines() As String
    
    my = ""
    For i = 1 To Len(it)
        a = Asc(Mid(it, i, 1))
        c = Hex(a)
        c = IIf(Len(c) = 1, "0" & c, c)
        b = b & IIf(a > 65 And a < 120, Chr(a), ".")
        my = my & c '& " "
        If i Mod 16 = 0 Then
            push lines(), my & "  [" & b & "]"
            my = Empty
            b = Empty
        End If
    Next
    
    If Len(b) > 0 Then
        If Len(my) < 48 Then
            my = my & String(48 - Len(my), " ")
        End If
        If Len(b) < 16 Then
             b = b & String(16 - Len(b), " ")
        End If
        push lines(), my & "  [" & b & "]"
    End If
        
    If Len(it) < 16 Then
        hexdump = my & "  [" & b & "]" & vbCrLf
    Else
        hexdump = Join(lines, vbCrLf)
    End If
    
    
End Function

Sub push(ary, value) 'this modifies parent ary object
    On Error GoTo init
    Dim x As Long
    x = UBound(ary) '<-throws Error If Not initalized
    ReDim Preserve ary(UBound(ary) + 1)
    ary(UBound(ary)) = value
    Exit Sub
init:     ReDim ary(0): ary(0) = value
End Sub


Sub StartBenchMark()
    startTime = GetTickCount()
End Sub

Function EndBenchMark() As String
    Dim endTime As Long, loadTime As Long
    endTime = GetTickCount()
    loadTime = endTime - startTime
    EndBenchMark = "  Time: " & Round(loadTime / 1000, 3) & " seconds"
End Function




Function FileExists(path As String) As Boolean
  On Error GoTo hell
    
  If Len(path) = 0 Then Exit Function
  If Right(path, 1) = "\" Then Exit Function
  If Dir(path, vbHidden Or vbNormal Or vbReadOnly Or vbSystem) <> "" Then FileExists = True
  
  Exit Function
hell: FileExists = False
End Function

Function ReadFile(filename)
  f = FreeFile
  temp = ""
   Open filename For Binary As #f        ' Open file.(can be text or image)
     temp = Input(FileLen(filename), #f) ' Get entire Files data
   Close #f
   ReadFile = temp
End Function
