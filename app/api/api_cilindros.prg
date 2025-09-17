function api_cilindros( oDom )

	do case
		case oDom:GetProc() == 'exe_consulta'        	; DoExe_Consulta( oDom )
		case oDom:GetProc() == 'nav_next'        			; DoNav_Next( oDom )
		case oDom:GetProc() == 'nav_top'							; DoNav_Top( oDom )
		case oDom:GetProc() == 'nav_end'							; DoNav_End( oDom )
		case oDom:GetProc() == 'nav_prev'							; DoNav_Prev( oDom )
		case oDom:GetProc() == 'nav_refresh'					; DoNav_Refresh( oDom )

			otherwise
			oDom:SetError( "Proc don't defined => " + oDom:GetProc())
	endcase

return oDom:Send()

// -------------------------------------------------- //


static function DoExe_Consulta( oDom )
	local hInfo := InitInfo( oDom )

	// Abrir base de datos
	IF ! OpenConnect(oDom, hInfo)
		return .f.
	endif

	// Obtener total de registros
	if ! TotalRows( oDom, hInfo )
		CloseConnect( oDom, hInfo )
	endif

	// Cargar datos de la primera página
	LoadRows( oDom, hInfo, .T. )  // .T. = inicializar browse

	// Cerrar conexión
	CloseConnect( oDom, hInfo )

	// Actualizar controles DOM
	Refresh_Nav( oDom, hInfo )

return .t.

// -------------------------------------------------- //

static function DoNav_Next( oDom )

	local hInfo	:= InitInfo( oDom )

	//	Open Database
	if ! OpenConnect( oDom, hInfo )
		return nil
	endif

	//	Refresh Total rows
	if ! TotalRows( oDom, hInfo )
		return nil
	endif

	//	Update page
	hInfo[ 'page' ]++

	if hInfo[ 'page' ] > hInfo[ 'page_total' ]
		hInfo[ 'page' ] := hInfo[ 'page_total' ]
	endif

	//	Load data...
	LoadRows( oDom, hInfo )

	//	Close database connection
	CloseConnect( oDom, hInfo )

	//	Refresh Dom
	Refresh_Nav( oDom, hInfo )

return nil

// -------------------------------------------------- //

static function Refresh_Nav( oDom, hInfo )
	oDom:Set( 'nav_total'		, hInfo[ 'total' ] )
	oDom:Set( 'nav_page'		, ltrim(str(hInfo[ 'page' ])) )
	oDom:Set( 'nav_page_rows'	, ltrim(str(hInfo[ 'page_rows' ])) )
	oDom:Set( 'nav_page_total'	, ltrim(str(hInfo[ 'page_total' ])) )
return nil

// -------------------------------------------------- //

static function DoNav_Top( oDom )
	local hInfo	:= InitInfo( oDom )

	// Abrir base de datos
	if ! OpenConnect( oDom, hInfo )
		return nil
	endif

	// Obtener total de registros
	if ! TotalRows( oDom, hInfo )
		return nil
	endif

	// Ir a primera página
	hInfo[ 'page' ] := 1

	// Cargar datos
	LoadRows( oDom, hInfo )

	// Cerrar conexión
	CloseConnect( oDom, hInfo )

	// Actualizar controles DOM
	Refresh_Nav( oDom, hInfo )

return nil

// -------------------------------------------------- //

static function DoNav_End( oDom )
	local hInfo	:= InitInfo( oDom )

	// Abrir base de datos
	if ! OpenConnect( oDom, hInfo )
		return nil
	endif

	// Obtener total de registros
	if ! TotalRows( oDom, hInfo )
		return nil
	endif

	// Ir a última página
	hInfo[ 'page' ] := hInfo[ 'page_total' ]

	// Cargar datos
	LoadRows( oDom, hInfo )

	// Cerrar conexión
	CloseConnect( oDom, hInfo )

	// Actualizar controles DOM
	Refresh_Nav( oDom, hInfo )

return nil

// -------------------------------------------------- //

static function DoNav_Prev( oDom )
	local hInfo	:= InitInfo( oDom )

	// Abrir base de datos
	if ! OpenConnect( oDom, hInfo )
		return nil
	endif

	// Obtener total de registros
	if ! TotalRows( oDom, hInfo )
		return nil
	endif

	// Ir a página anterior
	hInfo[ 'page' ]--

	if hInfo[ 'page' ] <= 0
		hInfo[ 'page' ] := 1
	endif

	// Cargar datos
	LoadRows( oDom, hInfo )

	// Cerrar conexión
	CloseConnect( oDom, hInfo )

	// Actualizar controles DOM
	Refresh_Nav( oDom, hInfo )

return nil

// -------------------------------------------------- //

static function DoNav_Refresh( oDom, hInfo )

	// Inicializar información si no se proporciona
	if hInfo == NIL
		hInfo := InitInfo( oDom )
	endif

	// Abrir base de datos
	if ! OpenConnect( oDom, hInfo )
		return nil
	endif

	// Obtener total de registros
	if ! TotalRows( oDom, hInfo )
		return nil
	endif

	// Cargar datos
	LoadRows( oDom, hInfo )

	// Actualizar controles DOM
	Refresh_Nav( oDom, hInfo )

	// Cerrar conexión
	CloseConnect( oDom, hInfo )

return nil

// -------------------------------------------------- //

static function TotalRows( oDom, hInfo )
	local oQry, nTotal := 0
	local cSql, cWhere := ""

	hInfo[ 'total' ] := 0

	// Construir cláusula WHERE para filtro general
	// if !empty(hInfo['filtro'])
	// 	cWhere := "(UPPER(codcli) LIKE '%" + Upper(hInfo['filtro']) + "%' OR UPPER(Nombre_tercero) LIKE '%" + Upper(hInfo['filtro']) + "%')"
	// endif

	// Construir SQL con filtros
	cSql := "SELECT COUNT(*) as total FROM tbcilindros"
	if !empty(cWhere)
		cSql += " WHERE " + cWhere
	endif

	// Consulta para obtener el total de registros
	oQry := hInfo[ 'db' ]:Query( cSql )

	IF oQry != NIL
		nTotal := oQry:total
		hInfo[ 'total' ] := nTotal
	ELSE
		oDom:SetError( 'Error counting records' )
		return .f.
	ENDIF

	// Calcular total de páginas
	hInfo[ 'page_total' ] := Int( hInfo[ 'total' ] / hInfo[ 'page_rows' ] ) + ;
		if( hInfo[ 'total' ] % hInfo[ 'page_rows' ] == 0, 0, 1 )

	// Validar página actual
	if hInfo[ 'page' ] > hInfo[ 'page_total' ] .or. hInfo[ 'page' ] <= 0
		hInfo[ 'page' ] := 1
	endif

return .t.

// -------------------------------------------------- //

static function LoadRows( oDom, hInfo, lInitBrw )
	local oQry, aClientes := {}, aRow := {}
	local cSql, cWhere := "", nRowInit

	hb_default( @lInitBrw, .f. )

	// if !empty(hInfo['filtro'])
	// 	cWhere := "(UPPER(codcli) LIKE '%" + Upper(hInfo['filtro']) + "%' OR UPPER(Nombre_tercero) LIKE '%" + Upper(hInfo['filtro']) + "%')"
	// endif

	// Calcular OFFSET para la paginación
	nRowInit := ( hInfo[ 'page' ] - 1 ) * hInfo[ 'page_rows']

	// Construir SQL con LIMIT, OFFSET y WHERE para filtros
	cSql := "SELECT row_id, cil_codigo FROM tbcilindros"

	if !empty(cWhere)
		cSql += " WHERE " + cWhere
	endif
	
	cSql += " LIMIT " + ltrim(str(hInfo[ 'page_rows' ])) + " OFFSET " + ltrim(str(nRowInit))

	oQry := hInfo[ 'db' ]:Query( cSql )

	IF oQry != NIL
		oQry:gotop()
		DO WHILE ! oQry:Eof()
			aRow := { 'ROW_ID' => oQry:row_id, 'CODCIL' => oQry:cil_codigo /*, 'NOMCLI' => hb_strtoutf8(oQry:Nombre_tercero)*/ }
			AADD( aClientes, aRow )
			oQry:Skip()
		END
	ELSE
		oDom:SetError( 'Error loading data' )
		return .f.
	ENDIF

	// Actualizar tabla
	oDom:TableSetData( 'cilindros', aClientes )

return .t.