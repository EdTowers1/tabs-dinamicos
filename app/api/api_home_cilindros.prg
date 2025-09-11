function api_home_cilindros( oDom )

    do case
        case oDom:GetProc() == 'ayuda_cliente'								; DoAyudaCliente( oDom )
        case oDom:GetProc() == 'seleccionar_cliente'					        ;  DoSelecionar_Cliente(oDom)

            otherwise 				
            oDom:SetError( "Proc don't defined => " + oDom:GetProc())
    endcase
	
retu oDom:Send()

// -------------------------------------------------- //

static function DoAyudaCliente( oDom )

    local cHtml := ULoadHtml( '../html/ayudas/ayuda_cliente.html'  )
    local o    := {=>}    

    o[ 'title' ]           := 'Ayuda de clientes'
    o[ 'centerVertical' ]  := .T.
    o[ 'draggable' ]       := .f.
    o[ 'focus']            := 'dlg_clientes-cFiltro'
    o[ 'width' ]           := 800
    

    oDom:SetDialog( 'ayuda_cliente', cHtml, nil, o )

retu nil

// -------------------------------------------------- //

static function DoSelecionar_Cliente(oDom)
    local cCodCli := AllTrim(oDom:Get('cCliente'))
    local oQry, hFull, cInfoCliente := ""
    local hInfo := InitInfo(oDom)
    local lConnected := .f.

    //oDom:console(oDom:GetAll(), 'GETALL')
    oDom:Set('cInfoCliente', "")

    // Validar código de cliente
    if hb_isNil(cCodCli) .or. empty(cCodCli)
        oDom:Set('cCliente', "")
        oDom:SetAlert("Debe ingresar el código del cliente.")
        oDom:focus('cCliente')
        return nil
    endif

    // Abrir conexión
    lConnected := OpenConnect(oDom, hInfo)
    if !lConnected
        oDom:SetError("No se pudo conectar a la base de datos.")
        return nil
    endif

    // Consultar cliente
    oQry := hInfo['db']:Query("SELECT * FROM munmacli WHERE codcli = '" + cCodCli + "'")
    if oQry == NIL .or. oQry:reccount() == 0
        oDom:SetAlert("No se encontró el cliente con código: " + cCodCli, "Error")
        oDom:Set('cCliente', "")
        oDom:focus('cCliente')
        CloseConnect(oDom, hInfo)
        return nil
    endif

    hFull := oQry:FillHRow()
    cInfoCliente := "ID: " + ltrim(str(hFull['row_id'])) + CHR(13) + CHR(10) + ;
        "Código: " + hFull['codcli'] + CHR(13) + CHR(10) + ;
        "Nombre: " + hb_strtoutf8(hFull['nomcli']) + CHR(13) + CHR(10)

    oDom:setDlg('home_cilindros')
    oDom:Set('cInfoCliente', cInfoCliente)
    // oDom:focus('cOrden')
    CloseConnect(oDom, hInfo)

return nil

// -------------------------------------------------- //

