function api_clientes( oDom )

	do case
		case oDom:GetProc() == 'init_browse'          	; InitBrowse(oDom)
		case oDom:GetProc() == 'nav_next'          			; Nav_Next(oDom)
		case oDom:GetProc() == 'nav_prev'          			; Nav_Prev(oDom)
		case oDom:GetProc() == 'nav_top'          			; Nav_Top(oDom)
		case oDom:GetProc() == 'nav_end'          			; Nav_End(oDom)
		case oDom:GetProc() == 'search_clientes'        ; Search_clientes(oDom)
		case oDom:GetProc() == 'select_cliente'         ; Select_cliente(oDom)
			otherwise
			oDom:SetError( "Proc don't defined => " + oDom:GetProc())
	endcase

return oDom:Send()

// -------------------------------------------------- //

static function InitBrowse( oDom )

	local hInfo := InitInfo( oDom )

	// Reutilizar la lógica de consulta y actualización
return DoBrowse( hInfo, oDom )

// -------------------------------------------------- //

static function DoBrowse( hInfo, oDom )

	local oQry, aClientes := {}, aRow := {}
	local nPageSize, nPageNumber, nPageCount := 0
	local cSearchData, nSearExact := 0
	local cSortBy := 'Nombre_tercero', cSortDirection := 'A'
	local cSql := ""
	local oQryPageCount

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

	cSql := "CALL usp_terceros_lista(" + ;
		ltrim(str(nPageSize)) + ", " + ;
		ltrim(str(nPageNumber)) + ", '" + cSearchData + "', " + ;
		ltrim(str(nSearExact)) + ", '" + cSortBy + "', '" + cSortDirection + "', @PageCount)"

	oQry := hInfo['db']:Query( cSql )

	if oQry != NIL
		oQry:GoTop()
		DO WHILE ! oQry:Eof()
			aRow := { 'ROW_ID' => oQry:row_id, 'CODCLI' => oQry:codcli, 'NOMCLI' => hb_strtoutf8(oQry:Nombre_tercero) }
			AADD( aClientes, aRow )
			oQry:Skip()
		END

		// Actualizar la tabla con los datos obtenidos
		oDom:TableSetData('clientes', aClientes)

		// Devolver al cliente el estado de paginación (útil para la UI)
		oDom:Set( 'nav_page', ltrim( str( nPageNumber ) ) )

	else
		oDom:SetError( "Errror loading data")
		CloseConnect(oDom, hInfo)
		return .f.
	endif

	// Cerrar la conexión
	CloseConnect(oDom, hInfo)

return .t.

// -------------------------------------------------- //

static function ChangePage( oDom, nDelta )

	local hInfo, nPage, lRes

	hInfo := InitInfo( oDom )

	// Abrir conexión para poder calcular totales
	if ! OpenConnect( oDom, hInfo )
		return .f.
	endif

	// Obtener total de filas/páginas
	if ! TotalRows( oDom, hInfo )
		CloseConnect( oDom, hInfo )
		return .f.
	endif

	// Conversión segura del valor de página
	if valtype( hInfo['page'] ) == 'N' .or. valtype( hInfo['page'] ) == 'I'
		nPage := hInfo['page']
	else
		nPage := Val( hInfo['page'] )
	endif

	// Aplicar delta
	nPage := nPage + nDelta

	// Limitar entre 1 y page_total
	if nPage < 1
		nPage := 1
	endif
	if HB_HHasKey( hInfo, 'page_total' ) .and. nPage > hInfo['page_total']
		nPage := hInfo['page_total']
	endif

	// Actualizar en memoria y en la respuesta (útil para la UI)
	hInfo['page'] := nPage
	oDom:Set( 'nav_page', ltrim( str( nPage ) ) )
	oDom:Set( 'nav_page_total', ltrim( str( hInfo['page_total'] ) ) )

	// Ejecutar búsqueda con el hInfo actualizado
	lRes := DoBrowse( hInfo, oDom )

	// Cerrar conexión
	CloseConnect( oDom, hInfo )

return lRes

// -------------------------------------------------- //

static function Nav_Next( oDom )

return ChangePage( oDom, 1 )

// -------------------------------------------------- //

static function Nav_Prev( oDom )

return ChangePage( oDom, -1 )

// -------------------------------------------------- //

static function Nav_Top( oDom )

	local hInfo := InitInfo( oDom )

	hInfo['page'] := 1

	// Informar al cliente
	oDom:Set( 'nav_page', '1' )

return DoBrowse( hInfo, oDom )

// -------------------------------------------------- //

static function TotalRows( oDom, hInfo )

	local oQry, nTotal := 0
	local cSql := ""

	hInfo['total'] := 0


	cSql := "SELECT COUNT(*) as total FROM m_terceros"

	// Aplicar filtro simple si existe
	if !empty( hInfo['filtro'] )
		cSql += " WHERE UPPER(nombre_tercero) LIKE '%" + Upper( hInfo['filtro'] ) + "%'"
	endif

	oQry := hInfo['db']:Query( cSql )

	if oQry != NIL
		nTotal := oQry:total
		hInfo['total'] := nTotal
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

static function Nav_End( oDom )

	local hInfo, lRes

	hInfo := InitInfo( oDom )

	// Abrir base de datos
	if ! OpenConnect( oDom, hInfo )
		return .f.
	endif

	// Obtener total de registros y páginas
	if ! TotalRows( oDom, hInfo )
		CloseConnect( oDom, hInfo )
		return .f.
	endif

	// Ir a última página
	hInfo['page'] := hInfo['page_total']

	// Cargar datos
	lRes := DoBrowse( hInfo, oDom )

	// Cerrar conexión
	CloseConnect( oDom, hInfo )

	// Enviar info de paginación al cliente
	oDom:Set( 'nav_page', ltrim( str( hInfo['page'] ) ) )
	oDom:Set( 'nav_page_total', ltrim( str( hInfo['page_total'] ) ) )

return lRes

// -------------------------------------------------- //

static function Search_clientes( oDom )

	local hInfo, cFilter, lRes

	hInfo := InitInfo( oDom )

	// Obtener filtro enviado desde el DOM (si viene en la petición)
	cFilter := oDom:Get( 'cFiltro', hInfo['filtro'] )
	hInfo['filtro'] := cFilter

	// Ir a la primera página al buscar
	hInfo['page'] := 1

	// Abrir conexión
	if ! OpenConnect( oDom, hInfo )
		return .f.
	endif

	// Calcular totales para la paginación
	if ! TotalRows( oDom, hInfo )
		CloseConnect( oDom, hInfo )
		return .f.
	endif

	// Cargar datos de la primera página
	lRes := DoBrowse( hInfo, oDom )

	// Cerrar conexión
	CloseConnect( oDom, hInfo )

	// Actualizar controles de paginación en el cliente
	oDom:Set( 'nav_total', hInfo['total'] )
	oDom:Set( 'nav_page', ltrim( str( hInfo['page'] ) ) )
	oDom:Set( 'nav_page_rows', ltrim( str( hInfo['page_rows'] ) ) )
	oDom:Set( 'nav_page_total', ltrim( str( hInfo['page_total'] ) ) )

return lRes

// -------------------------------------------------- //

static function Select_cliente( oDom )
	local hBrowse := oDom:Get( 'clientes' )
	local aSelected := {}
	local nRowId := 0
	local hRow := {}
	local cCodcli := ""
	local cNombre := ""
	local hInfo, oQry, hFull, cInfoCliente := NIL

	// Obtener selección
	if valtype( hBrowse ) == 'H' .and. HB_HHasKey( hBrowse, 'selected' )
		aSelected := hBrowse['selected']
	endif

	if valtype( aSelected ) == 'A' .and. len( aSelected ) > 0
		hRow := aSelected[1]
		nRowId := hRow['ROW_ID']

		// Intentar usar los datos ya presentes en la selección (evita consulta)
		if HB_HHasKey( hRow, 'CODCLI' )
			cCodcli := hRow['CODCLI']
		endif
		if HB_HHasKey( hRow, 'NOMCLI' )
			cNombre := hRow['NOMCLI']
		endif

		// // Si no tenemos código o nombre, hacer la consulta como fallback
		// if empty( cCodcli ) .or. empty( cNombre )
		// 	hInfo := InitInfo( oDom )
		// 	if ! OpenConnect( oDom, hInfo )
		// 		return nil
		// 	endif

		// 	oQry := hInfo['db']:Query( "SELECT * FROM m_terceros WHERE row_id = " + ltrim( str( nRowId ) ) + " LIMIT 1" )
		// 	if oQry != NIL .and. !oQry:Eof()
		// 		hFull := oQry:FillHRow()
		// 		cCodcli := hFull['codcli']
		// 		cNombre := hb_strtoutf8( hFull['nombre_tercero'] )
		// 	endif

		// 	CloseConnect( oDom, hInfo )
		// endif

		// Si ya tenemos código y/o nombre, llenar diálogo
		if !empty( cCodcli )
			cInfoCliente := "Código: " + cCodcli + CHR(13) + CHR(10) + ;
				"Nombre: " + cNombre + CHR(13) + CHR(10)

			oDom:SetDlg( 'home_cilindros' )
			oDom:Set( 'cCliente', cCodcli )
			oDom:Set( 'cInfoCliente', cInfoCliente )
			oDom:DialogClose( 'ayuda_cliente' )
		endif
	endif

return nil

