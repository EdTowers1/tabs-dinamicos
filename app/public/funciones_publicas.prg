function InitInfo( oDom )

	local hInfo := {=>}

	hInfo[ 'total' ] 		:= 0
	hInfo[ 'page' ] 		:= Val( oDom:Get( 'nav_page', '1' ))
	hInfo[ 'page_rows' ] 	:= Val( oDom:Get( 'nav_page_rows', '10' ))
	hInfo[ 'page_total' ] 	:= 0
	hInfo[ 'filtro' ]       := oDom:Get( 'cFiltro', '' )

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

