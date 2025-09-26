function InitInfo( oDom )

	local hInfo := {=>}

	hInfo[ 'total' ] 		:= 0
	hInfo[ 'page' ] 		:= Val( oDom:Get( 'nav_page', '1' ))
	hInfo[ 'page_rows' ] 	:= Val( oDom:Get( 'nav_page_rows', '10' ))
	hInfo[ 'page_total' ] 	:= 0
	hInfo[ 'filtro' ]       := oDom:Get( 'cFiltro', '' )

	// 	hInfo[ 'PageSize' ] 	:= Val( oDom:Get( 'nav_page_rows', '10' ))
	// hInfo[ 'PageNumber' ] 		:= Val( oDom:Get( 'nav_page', '1' ))
	// hInfo['SearchData'] 	:= oDom:Get( 'cFiltro', '' )
	// hInfo['SearchExact'] 	:= 0
	// hInfo[ 'SortBy' ]      := oDom:Get( 'sort_by', 'Nombre_tercero' )
	// hInfo[ 'SortDirection' ] := oDom:Get( 'sort_direction', 'A' )

return hInfo

// -------------------------------------------------- //

function OpenConnect( oDom, hInfo )

	Conect_database(oDom,@hInfo)

	IF hInfo[ 'lerror' ]
		oDom:SetError(hInfo['lerrordetalle'])
		return .f.
	ENDIF

return .t.

// -------------------------------------------------- //

function CloseConnect( oDom, hInfo )
	if HB_HHasKey( hInfo, 'db' ) .and. hInfo[ 'db' ] != NIL
		hInfo[ 'db' ]:End()
	endif
return nil

