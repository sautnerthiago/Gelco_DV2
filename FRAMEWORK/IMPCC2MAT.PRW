#Include "TOTVS.ch"

/*/{Protheus.doc} IMPCC2MAT
Atualiza campo CC2_MATRIZ via CSV
/*/

User Function IMPCC2MAT()

    Local aArea   := FWGetArea()
    Local aPergs  := {}
    Local aRet    := {}
    Local cArqSel := ""

    If !IsBlind()

        aAdd(aPergs, ;
            {6, "Arquivo CSV:", "", "@!", ".T.", ".T.", 120, .T., ;
            "Arquivos CSV (*.CSV)|*.CSV", "C:\"})

        If ParamBox(aPergs, "Importação CC2_MATRIZ", @aRet)

            cArqSel := AllTrim(aRet[1])

            If !Empty(cArqSel) .And. File(cArqSel)

                Processa({|| fImportaCC2(cArqSel)}, "Processando...")

            Else

                MsgStop("Arquivo não encontrado")

            EndIf

        EndIf

    EndIf

    FWRestArea(aArea)

Return


//==================================================================

Static Function fImportaCC2(cArqSel)

    Local oArquivo
    Local cLinha     := ""
    Local aLinha     := {}
    Local nLinha     := 0
    Local cLog       := ""
    Local cEstado    := ""
    Local cCodMun    := ""
    Local cMatriz    := ""
    Local cFilial    := ""

    Local cPastaLog  := ""
    Local cArquivoLog:= ""

    DbSelectArea("CC2")
    CC2->(DbSetOrder(1))

    oArquivo := FWFileReader():New(cArqSel)

    If oArquivo:Open()

        While oArquivo:HasLine()

            nLinha++

            cLinha := oArquivo:GetLine()

            // pula cabeçalho
            If nLinha == 1
                Loop
            EndIf

            // limpa quebra linha
            cLinha := StrTran(cLinha, Chr(13), "")
            cLinha := StrTran(cLinha, Chr(10), "")

            aLinha := zSplitPreserve(cLinha, ";")

            // valida layout
            If Len(aLinha) < 5

                cLog += "Linha inválida: " + cValToChar(nLinha) + CRLF
                Loop

            EndIf

            cFilial := AllTrim(aLinha[1])
            cEstado := AllTrim(aLinha[2])
            cCodMun := AllTrim(aLinha[3])
            cMatriz := AllTrim(aLinha[5])

            // procura município
            If CC2->(DbSeek(cFilial + cEstado + cCodMun))

                RecLock("CC2", .F.)

                    CC2->CC2_MATRIZ := cMatriz

                MsUnlock()

                cLog += "OK: " + cEstado + "/" + cCodMun + CRLF

            Else

                cLog += "Não encontrado: " + cEstado + "/" + cCodMun + CRLF

            EndIf

        EndDo

        oArquivo:Close()

        cPastaLog   := SubStr(cArqSel, 1, Rat("\", cArqSel))
        cArquivoLog := cPastaLog + "log_cc2_matriz.txt"

        MemoWrite(cArquivoLog, cLog)

        MsgInfo("Processamento finalizado." + CRLF + ;
                "Log: " + cArquivoLog)

    Else

        MsgStop("Erro ao abrir arquivo")

    EndIf

Return


//==================================================================

Static Function zSplitPreserve(cLinha, cSep)

    Local aRet  := {}
    Local nPos  := 1
    Local nNext := 0

    While .T.

        nNext := At(cSep, SubStr(cLinha, nPos))

        If nNext == 0
            AAdd(aRet, SubStr(cLinha, nPos))
            Exit
        EndIf

        AAdd(aRet, SubStr(cLinha, nPos, nNext - 1))

        nPos += nNext

    EndDo

Return aRet
