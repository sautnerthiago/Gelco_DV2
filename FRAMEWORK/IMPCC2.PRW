#Include "TOTVS.ch"

/*/{Protheus.doc} IMPCC2
Importação de Municípios CC2 - OBJETIVO: IMPORTAR MUNICIPIOS EX  
/*/

User Function IMPCC2()

    Local aArea   := FWGetArea()
    Local aPergs  := {}
    Local aRet    := {}
    Local cArqSel := ""

    If !IsBlind()

        aAdd(aPergs, ;
            {6, "Arquivo CSV:", "", "@!", ".T.", ".T.", 120, .T., ;
             "Arquivos CSV (*.CSV)|*.CSV", "C:\"})

        If ParamBox(aPergs, "Importação CC2", @aRet)

            cArqSel := AllTrim(aRet[1])

            If !Empty(cArqSel) .And. File(cArqSel)

                Processa({|| fImportaCC2(cArqSel)}, "Importando Municípios...")

            Else

                MsgStop("Arquivo inválido!")

            EndIf

        EndIf

    EndIf

    FWRestArea(aArea)

Return


//==================================================

Static Function fImportaCC2(cArqSel)

    Local oArquivo
    Local cLinAtu   := ""
    Local aLinha    := {}
    Local nLinha    := 0
    Local cLog      := ""

    Private lMsErroAuto    := .F.
    Private lMSHelpAuto    := .T.
    Private lAutoErrNoFile := .T.

    oArquivo := FWFileReader():New(cArqSel)

    If oArquivo:Open()

        Begin Transaction

            While oArquivo:HasLine()

                nLinha++

                cLinAtu := oArquivo:GetLine()

                // Ignora cabeçalho
                If nLinha == 1
                    Loop
                EndIf

                cLinAtu := StrTran(cLinAtu, Chr(13), "")
                cLinAtu := StrTran(cLinAtu, Chr(10), "")

                aLinha := zSplitPreserve(cLinAtu, ";")

                // Layout:
                // 1 = FILIAL
                // 2 = EST
                // 3 = CODMUN
                // 4 = MUNICIPIO

                If Len(aLinha) < 4
                    cLog += "Linha inválida: " + cLinAtu + CRLF
                    Loop
                EndIf

                fProcessaCC2(aLinha, @cLog)

            EndDo

        End Transaction

        MemoWrite(GetTempPath() + "log_importacao_cc2.txt", cLog)

        MsgInfo("Importação finalizada!")

        oArquivo:Close()

    Else

        MsgStop("Erro ao abrir arquivo!")

    EndIf

Return


//==================================================

Static Function fProcessaCC2(aLinha, cLog)

    Local cFilial := AllTrim(aLinha[1])
    Local cEstado := AllTrim(aLinha[2])
    Local cCodMun := AllTrim(aLinha[3])
    Local cMun    := AllTrim(aLinha[4])

    Local aDados  := {}

    DbSelectArea("CC2")
    CC2->(DbSetOrder(1))

    // Evita duplicidade
    If CC2->(MsSeek(cFilial + cEstado + cCodMun))

        cLog += "Município já existe: " + cCodMun + CRLF
        Return

    EndIf

    aAdd(aDados, {"CC2_FILIAL", cFilial, Nil})
    aAdd(aDados, {"CC2_EST",    cEstado, Nil})
    aAdd(aDados, {"CC2_CODMUN", cCodMun, Nil})
    aAdd(aDados, {"CC2_MUN",    cMun, Nil})

    lMsErroAuto := .F.

    MSExecAuto({|x,y| FISA010(x,y)}, aDados, 3)

    If lMsErroAuto

        MostraErro()

        cLog += "Erro ao importar: " + cCodMun + CRLF

    Else

        cLog += "OK: " + cCodMun + " - " + cMun + CRLF

    EndIf

Return


//==================================================

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
