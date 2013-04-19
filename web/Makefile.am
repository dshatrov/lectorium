lectoriumdir = $(datadir)/moment/lectorium

Lectorium.swf: Lectorium.as
	/opt/flex/bin/mxmlc -headless-server=true -static-link-runtime-shared-libraries=true $^
#	/opt/flex/bin/mxmlc -headless-server=true -static-link-runtime-shared-libraries=true -target-player=10.0 $^
#	/opt/flex/bin/mxmlc -debug=true $^

lectorium_DATA = common.tpl	\
		 Lectorium.swf

CLEANFILES = Lectorium.swf

