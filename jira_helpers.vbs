Function StringToCharCodeArray(str)
  Dim arr(), i, n

  n = Len(str)

  ReDim arr(n - 1)
  For i = 0 To n - 1
    arr(i) = Asc(Mid(str, i + 1, 1))
  Next
  StringToCharCodeArray = arr
End Function
