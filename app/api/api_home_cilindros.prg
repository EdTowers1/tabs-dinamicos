function api_home_cilindros( oDom )

    do case
        case oDom:GetProc() == 'ayuda_cliente'								; AyudaCliente( oDom )
        case oDom:GetProc() == 'init_browse'								; InitBrowse( oDom )
        case oDom:GetProc() == 'sync'										; sync( oDom )


        case oDom:GetProc() == 'agregar_cilindro'						    ; DoAgregarCilindro( oDom )
        case oDom:GetProc() == 'actualizar_movimiento'				        ; DoActualizarMovimiento( oDom )
        case oDom:GetProc() == 'obtener_consecutivo'				        ; DoObtenerConsecutivo( oDom )


            otherwise 				
            oDom:SetError( "Proc don't defined => " + oDom:GetProc())
    endcase
	
retu oDom:Send()

// -------------------------------------------------- //

static function AyudaCliente( oDom )

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

static function InitBrowse( oDom )
    local hInfo := InitInfo( oDom )
    local lRes := .f.

    // Abrir conexión y calcular totales primero para proteger contra SP que falla con 0 filas
    if OpenConnect( oDom, hInfo )
        if TotalRows( oDom, hInfo )
            lRes := Browse( hInfo, oDom )
        else
            lRes := .f.
        endif
        CloseConnect( oDom, hInfo )
    else
        lRes := .f.
    endif

return lRes

// -------------------------------------------------- //

static function Browse(hInfo, oDom)
    
    local oQry, aMovimientos := {}, aRow := {}
    local nPageSize, nPageNumber := 0
    local cSearchData, nSearExact := 0
    local cSortBy := 'docto', cSortDirection := 'D'
    local cTransac := 'INC' , cSucursal := '01'
    local cSql := ""

    // Abrir base de datos sólo si no existe conexión en hInfo
    if ! HB_HHasKey( hInfo, 'db' ) .or. hInfo['db'] == NIL
        IF ! OpenConnect(oDom, hInfo)
            return .f.
        endif
    endif

    // Asignar valores a las variables
    nPageSize := hInfo['page_rows']        // 10 por defecto
    nPageNumber := hInfo['page']           // 1 por defecto
    cSearchData := hInfo['filtro']         // filtro de búsqueda

    // Si ya ejecutamos TotalRows y el total es 0, no llamar al stored proc (evita fallos del driver)
    if HB_HHasKey( hInfo, 'total_checked' ) .and. hInfo['total'] == 0
        // Enviar tabla vacía y valores de paginación al cliente
        aMovimientos := {}
        oDom:TableSetData('movimientos', aMovimientos)
        oDom:Set( 'nav_total', 0 )
        // Mostrar página 1 por defecto cuando no hay filas
        hInfo['page'] := 1
        oDom:Set( 'nav_page', '1' )
        oDom:Set( 'nav_page_total', ltrim( str( hInfo['page_total'] ) ) )
        return .t.
    endif

    cSql := "CALL usp_documentos_lista(" + ;
        ltrim(str(nPageSize)) + ", " + ;
        ltrim(str(nPageNumber)) + ", '" + ;
        cTransac + "', '" + ;
        cSucursal + "', '" + ;
        cSearchData + "', " + ;
        ltrim(str(nSearExact)) + ", '" + ;
        cSortBy + "', '" + ;
        cSortDirection + "', @page_count )"

    // Ejecutar la consulta almacenada construida en cSql
    oQry := hInfo['db']:Query( cSql )

    if oQry != NIL
        oQry:GoTop()
        DO WHILE ! oQry:Eof()
            aRow := { 'ROW_ID' => oQry:row_id, 'DOCTO' => oQry:docto, 'FECHA' => dtoc( oQry:fecha ), 'NOMCLI' => hb_strtoutf8(oQry:nombre_tercero) }
            AADD( aMovimientos, aRow )
            oQry:Skip()
        END

        // Actualizar la tabla con los datos obtenidos
        oDom:TableSetData('movimientos', aMovimientos)

        // Si conocemos el total (TotalRows fue ejecutado), enviar también el total
        if HB_HHasKey( hInfo, 'total' )
            oDom:Set( 'nav_total', hInfo['total'] )
        endif

        // Devolver al cliente el estado de paginación (útil para la UI)
        oDom:Set( 'nav_page', ltrim( str( nPageNumber ) ) )
    else 
        oDom:SetError( "Error loading data")
        CloseConnect(oDom, hInfo)
        return .f.
    endif 
    
    CloseConnect(oDom, hInfo)

return .t.

// -------------------------------------------------- //

static function TotalRows( oDom, hInfo )

    local oQry, nTotal := 0
    local cSql := ""

    hInfo['total'] := 0

    cSql := "SELECT COUNT(*) as total FROM m_docto_header t1 LEFT JOIN m_terceros t2 ON t1.codcli = t2.codcli"

    // aplicar filtro si existe
    if !empty( hInfo['filtro'] )
        // busqueda por docto o por nombre del cliente
        cSql += " WHERE (UPPER(t1.docto) LIKE '%" +Upper( hInfo['filtro'] ) + "%'" + ;
            " OR UPPER(t2.nombre_tercero) LIKE '%" + Upper( hInfo['filtro'] ) + "%')"

    endif

    oQry := hInfo['db']:Query( cSql )

    if oQry != NIL
        nTotal := oQry:total
        hInfo['total'] := nTotal
        // Marcar que ya comprobamos el total para evitar llamadas al SP cuando no hay filas
        hInfo['total_checked'] := .T.
    else
        oDom:SetError( 'Error counting records' )
        return .f.
    endif

    // Calcular total de páginas
    hInfo['page_total'] := Int( hInfo['total'] / hInfo['page_rows'] ) + ;
        if( hInfo['total'] % hInfo['page_rows'] == 0, 0, 1 )

    // Validar página actual
    if hInfo['page'] > hInfo['page_total'] .or. hInfo['page'] <= 0
        hInfo['page'] := 1
    endif

return .t.

// -------------------------------------------------- //

static function sync( oDom )

    local cCodigo := ''
    local cDlg := 'home_cilindros'
    local oRow
    local hInfo
    local lConnected := .f.
    local cSql
    local oQry, hFull, cInfoCliente := ""
    local aCilindros := {}
    local aRow := {}
    local cSucursal := '01', cTransac := 'INC'

    oRow := oDom:Get( cDlg + '-row' )
    hInfo := InitInfo(oDom)

    if hb_isNil( oRow ) .or. empty( oRow )
        oRow := oDom:Get( 'row' )
    endif
    if hb_isObject( oRow ) .and. ! hb_isNil( oRow['value'] )
        oRow := oRow['value']
    endif

    cCodigo := oRow['DOCTO']

    if ValType( oRow ) $ 'AOH'
        cCodigo := AllTrim( iif( !hb_isNil( oRow['DOCTO'] ), oRow['DOCTO'], iif( !hb_isNil( oRow['docto'] ), oRow['docto'], '' ) ) )
    endif

    // Abrir conexión
    lConnected := OpenConnect(oDom, hInfo)
    if !lConnected
        oDom:SetError("No se pudo conectar a la base de datos.")
        return nil
    endif

    // Llamar al stored procedure que devuelve el body del documento
    cSql := "CALL usp_documentos_body_lista('" + cSucursal + "', '" + cTransac + "', '" + cCodigo + "')"

    oQry := hInfo['db']:Query( cSql )

    if oQry != NIL .and. ! oQry:Eof()
        // Si el SP devuelve también datos de cabecera en la primera fila, rellenarlos
        hFull := oQry:FillHRow()

        if ! hb_isNil( hFull['nit_tercero'] )
            cInfoCliente := "Código: " + hFull['nit_tercero'] + CHR(13) + CHR(10) + ;
                "Nombre: " + hb_strtoutf8( iif( hb_isNil( hFull['nombre_tercero'] ), "", hFull['nombre_tercero'] ) )
            oDom:Set('cInfoCliente', cInfoCliente)
        endif

        if ! hb_isNil( hFull['fecha'] )
            oDom:Set('cFecha', Str(Year(hFull['fecha']), 4) + "-" + StrZero(Month(hFull['fecha']), 2) + "-" + StrZero(Day(hFull['fecha']), 2))
        endif

        oDom:Set('cOrden', cCodigo)

        // Llenar tabla de cilindros con los datos del cuerpo del documento
        oQry:GoTop()
        DO WHILE ! oQry:Eof()
            if !hb_isNil(oQry:codigo_articulo) .and. !empty(oQry:codigo_articulo)
                aRow := { 'CODIGO' => oQry:codigo_articulo, 'CANTIDAD' => oQry:cantidad, 'PRECIO' => oQry:precio_docto }
                AADD( aCilindros, aRow )
            endif
            oQry:Skip()
        ENDDO

        // Actualizar tabla de cilindros
        oDom:TableSetData( 'cilindros', aCilindros )

        // Actualizar el campo JSON con la lista cargada
        oDom:Set('cilindros_json', hb_jsonEncode(aCilindros))
    else
        // No se obtuvieron filas: enviar tabla vacía
        oDom:TableSetData( 'cilindros', {} )
        oDom:Set('cilindros_json', hb_jsonEncode({}))
    endif

    CloseConnect(oDom, hInfo)

return nil

// -------------------------------------------------- //

static function DoAgregarCilindro(oDom)
    local cCodCil := AllTrim(oDom:Get('cNuevoCilindro'))
    local oQry, hFull
    local hInfo := InitInfo(oDom)
    local lConnected := .f.
    local aCilindros := {}
    local hCilindro := {=>}
    local cCilindrosJson
    local lExists := .F.
    local h, aRow := {}


    // validar código de cilindro
    if hb_isNil(cCodCil) .or. empty(cCodCil)
        oDom:Set('cNuevoCilindro', "")
        oDom:SetAlert("Debe ingresar el código del cilindro.")
        oDom:focus('cNuevoCilindro')
        return nil
    endif

    // Abrir conexión a la base de datos
    lConnected := OpenConnect(oDom, hInfo)
    if !lConnected
        oDom:SetError("No se pudo conectar a la base de datos.")
        return nil
    endif

    // consultar cilindro
    oQry := hInfo['db']:Query("SELECT * FROM m_cilindros WHERE codigo_cilindro = '" + cCodCil + "'")
    if oQry == NIL .or. oQry:reccount() == 0
        oDom:SetAlert("No se encontró el cilindro con código: " + cCodCil, "Error")
        oDom:Set('cNuevoCilindro', "")
        oDom:focus('cNuevoCilindro')
        CloseConnect(oDom, hInfo)
        return nil
    endif

    hFull := oQry:FillHRow()

    // Construir el hash del cilindro (ajusta los campos según tus columnas)
    hCilindro['CODIGO']  := hFull['codigo_cilindro']
    hCilindro['CANTIDAD']:= 1
    hCilindro['PRECIO']  := 0  // Ajusta si hay un campo de precio en m_cilindros

    // Obtener los cilindros actuales de la tabla desde el campo oculto JSON
    cCilindrosJson := oDom:Get('cilindros_json')
    if !empty(cCilindrosJson)
        //oDom:console("Cilindros JSON: " + cCilindrosJson)
        aCilindros := hb_jsonDecode(cCilindrosJson)

    else
        //oDom:console("No hay cilindros actuales, inicializando array vacío.")
        aCilindros := {}
    endif

    // Verificar duplicado: si ya existe un cilindro con el mismo código, mostrar alerta y no agregar
    if ValType(aCilindros) $ 'A'

        for each h in aCilindros
            if !hb_isNil(h['CODIGO']) .and. AllTrim(Upper(h['CODIGO'])) == AllTrim(Upper(hCilindro['CODIGO']))
                lExists := .T.
                exit
            endif
        next
        if lExists
            // cerrar conexion antes de retornar
            // oDom:SetAlert("El cilindro con código " + AllTrim(hCilindro['CODIGO']) + " ya está registrado.")
            oDom:Set('cNuevoCilindro', "")
            oDom:focus('cNuevoCilindro')
            CloseConnect(oDom, hInfo)
            return nil
        endif
    endif

    AAdd(aCilindros, hCilindro)

    // Actualizar la tabla de cilindros
    oDom:TableSetData('cilindros', aCilindros)

    // Actualizar el campo JSON con la lista actualizada
    oDom:Set('cilindros_json', hb_jsonEncode(aCilindros))

    oDom:Set('cNuevoCilindro', "")

    CloseConnect(oDom, hInfo)

return nil

// -------------------------------------------------- //

static function DoActualizarMovimiento(oDom, hInfo)

    local cDlg := 'home_cilindros'
    local cDocto := ''
    local cCodCli := ''
    local cCodCliActual := ''
    local oRow, oQry
    local aCilindros := {}
    local cCilindrosJson := ''
    local hCilindro
    local lClienteCambio := .f.
    local lCilindrosAgregados := .f.
    hb_default( @hInfo, NIL )

    if hInfo == NIL
        hInfo := InitInfo( oDom )
    endif

    // Obtener número de documento
    cDocto := AllTrim( oDom:Get( 'cOrden' ) )
    // Obtener código de cliente
    cCodCli := AllTrim( oDom:Get( 'cCliente' ) )

    // Abrir conexión
    if ! OpenConnect( oDom, hInfo )
        oDom:SetError( 'No se pudo conectar a la base de datos.' )
        return nil
    endif

    // Validar que se haya seleccionado un movimiento
    if empty( cDocto )
        oDom:SetAlert( 'Seleccione un movimiento (docto) para actualizar.' )
        CloseConnect( oDom, hInfo )
        return nil 
    endif

    // Obtener cilindros de la tabla visual
    cCilindrosJson := oDom:Get('cilindros_json')
    if !empty(cCilindrosJson)
        aCilindros := hb_jsonDecode(cCilindrosJson)
    else
        aCilindros := {}
    endif

    // Agregar cilindros nuevos a la base de datos
    for each hCilindro in aCilindros
        // Verificar si ya existe en m_docto_body
        oQry := hInfo['db']:Query( "SELECT 1 FROM m_docto_body WHERE docto = '" + cDocto + "' AND codigo_articulo = '" + hCilindro['CODIGO'] + "' LIMIT 1" )
        if oQry == NIL .or. oQry:reccount() == 0
            // Insertar nuevo cilindro
            hInfo['db']:SqlQuery( "INSERT INTO m_docto_body (docto, codigo_articulo, cantidad, precio_docto, transac_docto, sucursal) VALUES ('" + cDocto + "', '" + hCilindro['CODIGO'] + "', " + ltrim(str(hCilindro['CANTIDAD'])) + ", " + ltrim(str(hCilindro['PRECIO'])) + ", 'INC', '01')" )
            lCilindrosAgregados := .t.
        endif
    next

    // Si no hubo cambios, no mostrar mensaje ni refrescar
    if !lClienteCambio .and. !lCilindrosAgregados
        CloseConnect( oDom, hInfo )
        return nil
    endif

    oDom:SetAlert( 'Movimiento actualizado correctamente.' )

    CloseConnect( oDom, hInfo )

return nil

// -------------------------------------------------- //

static function DoObtenerConsecutivo( oDom )
    
    local input := {=>}
    local cInputJson := ""
    local cOutputJson := ""
    local oQry := NIL
    local hOut := {=>}
    local hInfo := InitInfo(oDom)

    input['codigo_sucursal']  := '01'
    input['tipo_transaccion'] := 'INC'
    input['ceros_izquierda']  := 1

    // Abrir conexión
    if ! OpenConnect( oDom, hInfo )
        oDom:SetError( 'No se pudo conectar a la base de datos.' )
        return nil
    endif

    // Preparar JSON de entrada
    cInputJson := hb_jsonEncode( input )

    // Asignar variables de sesión, invocar el procedimiento y leer la salida
    hInfo['db']:SqlQuery( "SET @input = '" + cInputJson + "'" )
    hInfo['db']:SqlQuery( "SET @output = NULL" )
    hInfo['db']:SqlQuery( "CALL usp_consecutivo_read(@input,@output)" )

    oQry := hInfo['db']:Query( "SELECT @output AS output" )
    if oQry != NIL .and. oQry:reccount() > 0
        cOutputJson := hb_strtoutf8( oQry:output )
    endif

    if ! empty( cOutputJson )
        hOut := hb_jsonDecode( cOutputJson )
        oDom:console( 'cConsecutivo', hOut['documento_generado'] )
        oDom:console( "Consecutivo JSON: " + cOutputJson )  
    else
        oDom:SetError( 'No se recibió respuesta del procedimiento consecutivo_read.' )
    endif

    CloseConnect( oDom, hInfo )
return nil