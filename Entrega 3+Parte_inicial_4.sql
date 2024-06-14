--================================================================================================================
/*
	************************************
    * Materia : Base de Datos Aplicada *
	* Curso y Comision: 02-5600		   *
	* Fecha de Entrega: 14/06		   *
	* Numero Grupo: 8				   *
	************************************
	Alumno/as:
		De Jesús, Rocio		  - 44.726.983
		Gliwa, Lucas		  - 43.915.507
		Masino, Nicolás		  - 42.855.529
		Rivas, Nahuel Alberto - 44.364.975
*/

-- ===============================================================================================================
--creaamos la base de datos con el nombre en criterio al enunciado "generar una db con nombre "COMXXXXGYY" 
--donde XXXX hace referencia al numero de comision y YY hace referencia al nro del grupo
IF  NOT EXISTS(SELECT 1 FROM SYS.DATABASES WHERE NAME = 'COM5600G08')
	CREATE DATABASE COM5600G08;
GO
USE COM5600G08
GO
set nocount on
GO
--creacion de esquema para la creación de la db
IF NOT EXISTS(SELECT 1 FROM SYS.schemas WHERE name LIKE 'dbHospital')
	 EXEC('CREATE SCHEMA dbHospital;');
GO
-- creación de esquema para los sp
IF NOT EXISTS(SELECT 1 FROM SYS.schemas WHERE name LIKE 'spHospital')
	 EXEC('CREATE SCHEMA spHospital;');
GO
-- creación de esquema para las funciones
IF NOT EXISTS(SELECT 1 FROM SYS.schemas WHERE name LIKE 'fnHospital')
	 EXEC('CREATE SCHEMA fnHospital;');
GO
-- creación de esquema para los log
IF NOT EXISTS(SELECT 1 FROM SYS.schemas WHERE name LIKE 'logHospital')
	 EXEC('CREATE SCHEMA logHospital;');
GO

--**********CREACION DE TABLAS***********

--los nombres de las tablas son el singular --no es 'pacientes' es 'paciente'
--tabla paciente

-- sys.tables, proporciona información específica sobre todas las tablas de usuario en la base de datos actual.
-- SYS.all_objects,contiene información sobre todos los objetos en la base de datos : vistas, sp, tablas, funciones, trigges
--dependiendo de la necesita de información que requerimos, una vista puede ser mas útil que la otra, en este caso, sería más óptimo utilizar sys.tables, en contexto de performance.

--- tabla paciente

-- otra forma de consultar si existe la tabla 

IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'paciente'   AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
	CREATE TABLE dbHospital.paciente(

		id_historia_clinica		int  identity(1,1) PRIMARY KEY, -- ponemos identity?-charlarlo con el grupo-
		nombre					varchar(30) NOT NULL,
		apellido				varchar(30) NOT NULL,
		apellidoMaterno			varchar(30) NOT NULL,
		fechaNacimiento			datetime NOT NULL, -- consultar con el grupo
		tipoDoc					varchar(10) NOT NULL,
		numDoc					char(8) NOT NULL,
		sexoBio					char NOT NULL,
		genero					varchar(20) NOT NULL,
		nacionalidad			varchar (20) NOT NULL,
		fotoPerfil				varchar (50) NOT NULL,
		mail					varchar(50) UNIQUE NOT NULL,
		telFijo				    varchar(14) NOT NULL,
		telAlt					varchar(14),
		telLaboral				varchar(14),
		fechaRegistro			date NOT NULL,
		fechaAct				date NOT NULL,
		usuarioAct				varchar(40),
		CONSTRAINT CK_mail CHECK (
			mail LIKE '%@%'							-- Debe contener al menos un símbolo "@".
			AND mail LIKE '%.%'						-- Debe contener al menos un punto ".".
			AND mail NOT LIKE '%@%@%'				-- Debe tener solo un símbolo "@".
			AND LEN(mail) > 5						-- Debe tener al menos 5 caracteres.
			AND LEN(mail) < 30						-- Debe tener hasta 30 caracteres.
		),
		CONSTRAINT CK_telFijo CHECK(
			LEN(telFijo) >= 10						-- Debe tener al menos 10 caracteres.
			AND LEN(telFijo) <= 13					-- Debe tener como máximo 13 caracteres.
			--AND ISNUMERIC(telFijo) = 1			-- Debe ser numérico.
			AND telFijo NOT LIKE '%[^(0-9)\-]%'		-- Debe contener solo dígitos numéricos.
		),
		CONSTRAINT CK_telAlt CHECK((
			LEN(telAlt) >= 10						-- Debe tener al menos 10 caracteres.
			AND LEN(telAlt) <= 14					-- Debe tener como máximo 13 caracteres.
			--AND ISNUMERIC(telAlt) = 1				-- Debe ser numérico.
			AND telAlt NOT LIKE '%[^(0-9)\-]%')		-- Debe contener solo dígitos numéricos.
			--OR telAlt IS NULL						--Puede ser NULL-> no es extrictamente necesario, ya se especifíco al momento de crear el campo	
		),
		CONSTRAINT CK_telLaboral CHECK((
			LEN(telLaboral) >= 10					-- Debe tener al menos 10 caracteres.
			AND LEN(telLaboral) <= 13				-- Debe tener como máximo 13 caracteres.
			--AND ISNUMERIC(telLaboral) = 1			-- Debe ser numérico.
			AND telLaboral NOT LIKE '%[^(0-9)\-]%')	-- Debe contener solo dígitos numéricos.
			--OR telLaboral IS NULL					-- Puede ser NULL ->no es extrictamente necesario, ya se especifíco al momento de crear el campo					
		),
		CONSTRAINT CK_sexoBio CHECK(
			sexoBio IN ('F','M')					-- Debe ser 'Femenino' o 'Masculino'
		),
		CONSTRAINT CK_nroDoc CHECK (
			numDoc NOT LIKE '[^0-9]'				-- Debe ser unicamente dígitos. " [^0-9] " -> 'no puede ser distinto a numerico' 
			AND LEN(numDoc) >= 7					-- Debe tener una longitud mayor o igual a dígitos.
		)
	);
END


GO -- NO OLVIDARSE EL GO

--******************************************************************************************

--tabla estudio

 
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'estudio'   AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
		CREATE TABLE dbHospital.estudio(
			id_estudio			int PRIMARY KEY,
			fecha				datetime NOT NULL,
			nombreEstudio		varchar(80) NOT NULL,
			autorizado			BIT DEFAULT 0, -- tipo de dato BIT- > dato bool,0 =false, 1= true , el contexto -> 0= no autorizado, 1= autorizado 
			docResultado		varchar(100) NOT NULL,
			imagenResultado	    varchar(100) NOT NULL,
			id_hist_clinica		int,
			CONSTRAINT fk_estudioPaciente FOREIGN KEY (id_hist_clinica) REFERENCES dbHospital.paciente(id_historia_clinica)
		);
END
GO

--******************************************************************************************

--tabla usuario

-- FUNCION de tipo ESCALAR, valida/verifica que el DNI ingresado en la tabla usuario, exista (y sea el mismo) en la tabla paciente.

CREATE OR ALTER FUNCTION fnHospital.verificacionDocPaciente(@dni CHAR(8))
RETURNS BIT
AS
   BEGIN
		DECLARE @dniPaciente CHAR(8) = 'datorand'; -- inicializamos la variable dniPaciente con una cadena, primero para que no tome datos basura, 
													--segundo, para que sepamos con certeza que si no existe el documento en la tabla paciente, la comparación efectivamente va a ser falsa
		SELECT @dniPaciente = numDoc FROM dbHospital.paciente WHERE numDoc = @dni
		IF(@dniPaciente <> @dni)
			RETURN 0

		RETURN 1
	END
GO	

IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'usuario' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN		
	

	-- usuario es DEBIL de PACIENTE, ya que no existiria un usuario sin la existencia de un paciente.
	CREATE TABLE dbHospital.usuario(
		id_usuario_paciente		int,
		id_doc_paciente			char(8), --> DNI , debe coincidir con el documento, para eso la funcion de arriba
		contrasenia				varchar(40) NOT NULL,
		fechaCreacion			date NOT NULL,
	
		CONSTRAINT pk_usuario PRIMARY KEY (id_usuario_paciente,id_doc_paciente),
		CONSTRAINT fk_usuarioPaciente FOREIGN KEY (id_usuario_paciente) REFERENCES dbHospital.paciente(id_historia_clinica),

		CONSTRAINT ck_contraseniaUsu CHECK (
			LEN(contrasenia) >= 8								-- Longitud mínima de 8 caracteres
			AND CHARINDEX(UPPER(contrasenia), contrasenia) > 0	-- Al menos una letra mayúscula
			AND CHARINDEX(LOWER(contrasenia), contrasenia) > 0	-- Al menos una letra minúscula
			AND PATINDEX('%[0-9]%', contrasenia) > 0			-- Al menos un número
		),
		CONSTRAINT ck_idPaciente CHECK (
			id_doc_paciente NOT LIKE '[^0-9]' --es necesario este check, existiendo la funcion?
			AND LEN(id_doc_paciente) >= 7
			AND fnHospital.verificacionDocPaciente(id_doc_paciente) = 1 --aca llamamos a la funcion para verificar que exista y coincidencia del DNI de la tabla PACIENTE, entonces se valida la cuenta usuario
		)
	);
END
GO

--******************************************************************************************

--tabla domicilio
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'domicilio' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN


	CREATE TABLE dbHospital.domicilio(
		id_domicilio		int IDENTITY (1,1) PRIMARY KEY ,--y si ponemos identity
		calle				varchar(30) NOT NULL,
		numero				int NOT NULL,
		piso				int,
		departamento		int,
		codigoPostal		int NOT NULL,
		pais				varchar(20) NOT NULL,
		provincia			varchar(30) NOT NULL,
		localidad			varchar(30)  NOT NULL,
		id_hist_clinica		int,
		CONSTRAINT fk_domicilioPaciente FOREIGN KEY (id_hist_clinica) REFERENCES dbHospital.paciente(id_historia_clinica),
		CONSTRAINT ck_cpDomicilio CHECK (LEN(codigoPostal) = 4 )
	);
END
GO

--******************************************************************************************

--tabla cobertura

IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'cobertura' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
	CREATE TABLE dbHospital.cobertura(
		id_cobertura		int PRIMARY KEY, -- vamo a poner un codigo de 7 digitos, asi sacamos el identity un poco
		imagenCredencial	varchar(80) NOT NULL, -- como planteamos la imagen? es un link?
		nroSocio			int NOT NULL,
		fechaRegistro		date NOT NULL, --es necesario?
		id_hist_clinica		int,
		CONSTRAINT fk_coberturaPaciente FOREIGN KEY (id_hist_clinica) REFERENCES dbHospital.paciente(id_historia_clinica),
		CONSTRAINT ck_idCobertura CHECK ( LEN (id_cobertura) = 7) --podemos sacarlo tranqui
	);
END
GO
--******************************************************************************************

--tabla prestador

IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'prestador' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN

	CREATE TABLE dbHospital.prestador (
		id_prestador		int PRIMARY KEY,
		nombrePrestador		varchar(50) UNIQUE NOT NULL,
		planPrestador		varchar(50) NOT NULL,
		activo				bit default 1,
		id_cobertura		int,
		CONSTRAINT fk_prestadorCobertura FOREIGN KEY (id_cobertura) REFERENCES dbHospital.cobertura (id_cobertura),
		CONSTRAINT ck_idPrestador CHECK (LEN (id_prestador) = 3)
	);
END
GO

--******************************************************************************************

--tabla estado de turno
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'estadoTurno' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
	CREATE TABLE dbHospital.estadoTurno(
		id_estado_turno		int PRIMARY KEY,
		estado	varchar(20) NOT NULL,

		CONSTRAINT CK_estadoTurno CHECK(
			UPPER(estado) = 'ATENDIDO'
			OR UPPER(estado) = 'AUSENTE'
			OR UPPER(estado) = 'CANCELADO'
		)
	);
END
GO
--******************************************************************************************

--tabla tipo de turno
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'tipoTurno' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
	CREATE TABLE dbHospital.tipoTurno(--no se si las campos estan bien
		id_tipo_turno		int PRIMARY KEY,
		tipoTurno		varchar(10) NOT NULL,

		CONSTRAINT CK_tipoTurno CHECK(
			UPPER(tipoTurno) = 'PRESENCIAL'
			OR UPPER(tipoTurno) = 'VIRTUAL'
		)
	);
END
go

--*******************************************************************************************

-- tabla sede de atencion
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'sedeDeAtencion' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
	CREATE TABLE dbHospital.sedeDeAtencion(
		id_sede			 int PRIMARY KEY,
		nombreDeSede	 varchar(30) NOT NULL,
		direccionSede	 varchar(80) NOT NULL
	);
END
GO

--******************************************************************************************

-- tabla especialidad
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'especialidad' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN

	CREATE TABLE dbHospital.especialidad(
		id_especialidad			int PRIMARY KEY, --usamos alguna constraint mas? que criterio tienen los id de especialidad?
		nombreEspecialidad		varchar(40),

		CONSTRAINT ck_idEspecialidad CHECK ( LEN(id_especialidad) = 5) --decidimos que, el id debe tener 5 digitos (esto podemos borrarlo)
	);
END	
GO

--******************************************************************************************

-- tabla medico
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'medico' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
	CREATE TABLE dbHospital.medico(
		id_medico				 int PRIMARY KEY,-- -usamos alguna constraint mas? que criterio tienen los id de especialidad? charlarlo con el grupo
		nombre					 varchar(30) NOT NULL,
		apellido				 varchar(30) NOT NULL,
		nroMatricula			 int NOT NULL,
		id_especialidad_medico	 int,
		CONSTRAINT fk_medicoEspecialidad FOREIGN KEY (id_especialidad_medico) REFERENCES dbHospital.especialidad (id_especialidad),
		CONSTRAINT ck_idMedico CHECK (LEN(id_medico) = 3) --podemos borrarlo
	);
END
GO

--******************************************************************************************

--tabla dias x sede
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'diasXsede' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
	CREATE TABLE dbHospital.diasXsede(
		id_dia_sede			int PRIMARY KEY,--que criterio tienen los ID de las sede?
		dia				varchar(10) NOT NULL, 
		horaInicio		varchar(10) NOT NULL, 
		id_medico	    int,
		id_sede_atencion int,
		CONSTRAINT chk_horaInicio CHECK (
    EXISTS (
        SELECT 1
        FROM dbHospital.diasXsede AS t_anterior
        WHERE t_anterior.id_medico = dbHospital.diasXsede.id_medico
        AND t_anterior.id_sede_atencion = dbHospital.diasXsede.id_sede_atencion
        AND t_anterior.dia = dbHospital.diasXsede.dia
        AND (dbHospital.diasXsede.horaInicio = DATEADD(MINUTE, 15, t_anterior.horaInicio)
            OR
            (
                NOT EXISTS (
                    SELECT 1
                    FROM dbHospital.diasXsede AS primer_turno
                    WHERE primer_turno.id_medico = dbHospital.diasXsede.id_medico
                    AND primer_turno.id_sede_atencion = dbHospital.diasXsede.id_sede_atencion
                    AND primer_turno.dia = dbHospital.diasXsede.dia
                    AND primer_turno.horaInicio < dbHospital.diasXsede.horaInicio
                )
            )
        )
    )
)

--El EXISTS verifica que la tabla tenga algun turno en la misma sede, mismo medico y mismo dia cuya hora de inicio sea exactamente
--15 minutos antes de la hora de inicio del turno actual. El NOT EXISTS es para verificar si el turno actual es el primer turno del día en la misma sede y para el mismo medico del turno actual (ya que si es el primer turno la condición de EXISTS no se cumple)
		CONSTRAINT fk_diasXsedeMedico FOREIGN KEY (id_medico) REFERENCES dbHospital.medico (id_medico),
		CONSTRAINT fk_diasXsedeSedeAtencion FOREIGN KEY (id_sede_atencion) REFERENCES dbHospital.sedeDeAtencion (id_sede),
		CONSTRAINT UQ_diasSede UNIQUE (id_dia_sede, id_medico, dia, horaInicio) -- para un mismo dia, misma sede, mismo medico y misma hora solo existe 1 turno, por ende debe ser unico
	);
END
GO

--******************************************************************************************

--tabla reserva de turno medico
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'reservaTurnoMedico' AND schema_id = SCHEMA_ID('dbHospital')) 
BEGIN
	CREATE TABLE dbHospital.reservaTurnoMedico(
		id_reserva_turno	int identity(1,1) PRIMARY KEY,
		fecha				date NOT NULL,
		hora				time NOT NULL,
		id_diaSede			int,
		id_paciente			int,
		id_estado			int,
		id_tipoTurno		int,
		id_medico			int,
		id_especialidad		int,
		id_sedeAten			int,
	
		CONSTRAINT FK_reservaDiasxSede FOREIGN KEY (id_diaSede) REFERENCES dbHospital.diasXsede (id_dia_sede),
		CONSTRAINT FK_reservaPaciente FOREIGN KEY (id_paciente) REFERENCES dbHospital.paciente (id_historia_clinica),
		CONSTRAINT FK_reservaEstadoTurno FOREIGN KEY (id_estado) REFERENCES dbHospital.estadoTurno (id_estado_turno),
		CONSTRAINT FK_reservaTipoTurno FOREIGN KEY (id_tipoTurno) REFERENCES dbHospital.tipoTurno(id_tipo_turno),
		CONSTRAINT FK_reservaMedico FOREIGN KEY (id_medico) REFERENCES dbHospital.medico (id_medico),
		CONSTRAINT FK_reservaEspecialidadMed FOREIGN KEY (id_especialidad) REFERENCES dbHospital.especialidad (id_especialidad),
		CONSTRAINT FK_reservaSede FOREIGN KEY (id_sedeAten) REFERENCES dbHospital.sedeDeAtencion (id_sede)
	);
END
GO

--***********************************************************************************************************


-- ***************************** STORE PROCEDURES **************************


-- ***************************** INSERCION DE DATOS **************************
CREATE OR ALTER PROCEDURE spHospital.insercionDatos(
		@nombreEsquema NVARCHAR(128),   -- Nombre del esquema /PUEDE SER OPCIONAL, DEPENDIENDO DE LA FORMA QUE TOMEMOS
		@nombreTabla NVARCHAR(128),  -- Variable que contendra el nombre de la tabla a insertar
		@campos NVARCHAR(MAX),    -- Variable que contiene los nombres de los campos a ingresar datos
		@valores NVARCHAR(MAX)  -- Variable que contiene la lista de valores
		)
		AS    
	BEGIN
		-- Inicio de la sección TRY para manejo de errores
		BEGIN TRY
			-- Declaración de una variable para almacenar la consulta SQL dinámica
		
			DECLARE @sql NVARCHAR(MAX);

			-- Construcción de la consulta de inserción utilizando SQL dinámico
			--forma 1, con el esquema  pasado como parametro
			SET @sql = N'INSERT INTO '+ QUOTENAME(@nombreEsquema)+'.'+QUOTENAME(@nombreTabla)+
			'(' + @campos + ') VALUES (' + @valores + ');';
			--segunda forma
			 --SET @sql = N'INSERT INTO dbHospital.'+ QUOTENAME(@nombreTabla) + N'(' + @campos + ')' + N'VALUES' + '(' + @valores + ');';
	

			-- Ejecución de la consulta SQL dinámica
			EXEC sp_executesql @sql; --  sp_executesql permite ejecutar SQL dinámico con seguridad, especialmente cuando se pasan parámetros.
		END TRY
			-- Inicio de la sección CATCH para manejo de errores
		BEGIN CATCH
			-- Declaración de variables para capturar el mensaje y detalles del error
			DECLARE @mensajeError NVARCHAR(4000);
			DECLARE @gravedadDelError INT;
			DECLARE @estadoDelError INT;

			-- Obtención de los detalles del error ocurrido
			SELECT @mensajeError = ERROR_MESSAGE(),
				   @gravedadDelError = ERROR_SEVERITY(),
				   @estadoDelError = ERROR_STATE();
			-- Lanzamiento del error capturado para informar del fallo
			RAISERROR (@mensajeError, @gravedadDelError, @estadoDelError);
		END CATCH;
	END
GO

-- ***************************** MODIFICADO DE DATOS **************************

CREATE OR ALTER PROCEDURE spHospital.modificacionDatos(
    @nombreEsquema NVARCHAR(128), -- Nombre del esquema 
    @nombreTabla NVARCHAR(128),-- Variable que contendra el nombre de la tabla a modificar
    @clausulaSet NVARCHAR(MAX), -- Variable que contiene el contenido de la clausula set
    @clausulaWhere NVARCHAR(MAX)-- Variable que contiene el contenido de la clausula where
	) 
	AS
BEGIN
    BEGIN TRY
        DECLARE @sql NVARCHAR(MAX);

        -- Construcción de la consulta de actualización utilizando SQL dinámico
        SET @sql = N'UPDATE ' + QUOTENAME(@nombreEsquema) + '.' + QUOTENAME(@nombreTabla) +
                   N' SET ' + @clausulaSet +
                   N' WHERE ' + @clausulaWhere + ';';

        -- Ejecución de la consulta SQL dinámica
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        -- Manejo de errores
        DECLARE @mensajeError NVARCHAR(4000);
        DECLARE @gravedadDeError INT;
        DECLARE @estadoDelError INT;

        SELECT @mensajeError = ERROR_MESSAGE(),
               @gravedadDeError = ERROR_SEVERITY(),
               @estadoDelError = ERROR_STATE();

        -- Lanzar el error
        RAISERROR (@mensajeError, @gravedadDeError, @estadoDelError);
    END CATCH;
END
GO

-- ***************************** ELIMINACION DE DATOS **************************
CREATE OR ALTER PROCEDURE spHospital.borrarDatos(
    @nombreEsquema NVARCHAR(128),  -- Nombre del esquema
    @nombreTabla NVARCHAR(128),   -- Nombre de la tabla
    @clausuraWhere NVARCHAR(MAX)  -- Condición para la eliminación
	)
	AS
BEGIN
    BEGIN TRY
        DECLARE @sql NVARCHAR(MAX);

        -- Construcción de la consulta de eliminación utilizando SQL dinámico
        SET @sql = N'DELETE FROM ' + QUOTENAME(@nombreEsquema) + N'.' + QUOTENAME(@nombreTabla) +
                   N' WHERE ' + @clausuraWhere + N';';

        -- Ejecución de la consulta SQL dinámica
        EXEC sp_executesql @sql;
    END TRY
    BEGIN CATCH
        -- Manejo de errores
        DECLARE @mensajeError NVARCHAR(4000);
        DECLARE @gravedadDeError INT;
        DECLARE @estadoDelError INT;

        SELECT @mensajeError = ERROR_MESSAGE(),
               @gravedadDeError = ERROR_SEVERITY(),
               @estadoDelError = ERROR_STATE();

        -- Lanzar el error
        RAISERROR (@mensajeError, @gravedadDeError, @estadoDelError);
    END CATCH;
END
GO


--*********CREACION DE ROLES***********
--ACLARACION: No hace falta aclarar esquema, los roles son aplicados a nivel base de datos.
IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'Paciente' AND type = 'R') 
BEGIN
CREATE ROLE Paciente
END
GO

IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'Personal Administrativo' AND type = 'R') 
BEGIN
CREATE ROLE Personal Administrativo
END
GO

IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'Personal Tecnico clinico' AND type = 'R') 
BEGIN
CREATE ROLE Personal Tecnico clinico
END
GO

IF NOT EXISTS ( SELECT 1 FROM sys.tables  WHERE name = 'Administrador General' AND type = 'R') 
BEGIN
CREATE ROLE Administrador General
END
GO

--*********PERMISOS DE ROLES**********
--no se aclara en tp por lo que lo hacemos a consideracion de nuestra opninion
--para paciente no se como hacer que solo pueda ver sus datos... hay que crear alguna vista

GRANT EXECUTE ON dbHospital.insercionDatos to Medico
GRANT SELECT ON dbHosptial.paciente,dbHosptial.estudio,dbHosptial.cobertura to Medico
GO

GRANT EXECUTE ON dbHospital.borrarDatos to Personal Administrativo --peligrosa, pero no le podemos dejar solo el borrador a administrador general...
GRANT EXECUTE ON dbHospital.modificacionDatos to Personal Administrativo
GRANT EXECUTE ON dbHospital.insercionDatos to Personal Administrativo
GRANT SELECT ON dbHosptial.paciente,dbHosptial.reservaTurnoMedico,dbHosptial.cobertura,dbHospital.prestador,dbHospital.estadoTurno,dbHospital.tipoTurno,
db.Hospital.medico,dbHospital.especialidad to Personal Administrativo
GO


GRANT EXECUTE ON dbHospital.insercionDatos to Personal Tecnico clinico
GRANT SELECT ON dbHosptial.paciente,dbHosptial.estudio to Personal Tecnico clinico
GO

GRANT EXECUTE ON dbHospital.borrarDatos to Administrador General
GRANT EXECUTE ON dbHospital.modificacionDatos to Administrador General
GRANT EXECUTE ON dbHospital.insercionDatos to Administrador General
GRANT CONTROL ON SERVER to Administrador General --creo que grant control on server ya contiene a las sp
GO

--*******Importacion de archivos***********
CREATE OR ALTER PROC spHospital.ArchivoEspecialidad @rutaCSV NVARCHAR(500)
AS
	SET NOCOUNT ON;
	-- Trabajamos con tabla temporal para poder tomar los datos del archivo y modificarlos para su proxima inserccion, luego la borramos
	--por ejemplo, la especialidad la tenemos que sacar del archivo de medico, pero tiene mas datos que solo eso, tiene la siguiente estructura:
	IF OBJECT_ID('tempdb..#CSV_Medico') IS NOT NULL
	CREATE TABLE #CSV_Medico (
		nombre VARCHAR(30) NOT NULL,
		apellido VARCHAR(30) NOT NULL,
		especialidad VARCHAR(50) NOT NULL,
		nroColegiado VARCHAR(8) NOT NULL,  --se ve que es 6 en archivo, podemos aplicar un check en tabla original? nroColegiado=Matricula
	)

	-- Declarar variables
	DECLARE @INSERCCION AS NVARCHAR(MAX)
		, @mensaje AS VARCHAR(250)
		, @cant AS INT;
	
	-- Insertar valores del csv en la tabla temporal
	SET @INSERCCION = N'BULK INSERT #CSV_Medico FROM ''' + @rutaCSV + N''' WITH(CHECK_CONSTRAINTS, CODEPAGE = ''65001'', FIRSTROW = 2, FIELDTERMINATOR = '';'')'
	--codepage es con acp solo si estoy seguro de que la pagina de codigos activa de sistema contiene todos los caracteres que se encuentre en el archivo
	--firstrow arranca en 2 para saltear el encabezado... sino seria 1
	--fieldterminator es como se encuentran separados los elementos, se ve abriendo el archivo en un bloc de notas...
	BEGIN TRY
		BEGIN TRANSACTION
		
		EXEC sp_executesql @INSERCCION --para evitar inyecciones

		-- TRANSFORMACION DE DATOS
		UPDATE #CSV_Medico
		SET especialidad = UPPER(especialidad) --es necesario? no tenemos ninguna condicion que nos oblige
		
		UPDATE #CSV_Medico
		SET nombre = UPPER(nombre) --es necesario? no tenemos ninguna condicion que nos oblige
		--CONSIDERAR QUE LUEGO SE HACE COMPARACION PARA VER SI EXISTE, POR LO TANTO HAY QUE ACOMODARLO AL FORMATO DE LA TABLA MAS QUE UPPER Y LOWWER...
		
		INSERT INTO dbHospital.especialidad (nombreEspecialidad)
		SELECT DISTINCT a.especialidad COLLATE Modern_Spanish_CI_AI FROM #csvMedico a
		WHERE NOT EXISTS (SELECT 1 FROM dbHospital.especialidad b
							WHERE a.especialidad = b.nombreEspecialidad)
		
		SET @cant = @@ROWCOUNT;

		SET @mensaje = 'La tabla de especialidades ha recibido' + CAST(@cant AS varchar) + ' especialidades nuevas';
		PRINT @mensaje;

		--EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'   es requisito documentar esto?

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		PRINT 'Error en la carga de especialidades'
		PRINT 'Linea: ' + ERROR_LINE() + ' - Error: ' + ERROR_MESSAGE()
		
		IF @@TRANCOUNT > 0
		--variable del sistema, indica si hay una transaccion activa 
			ROLLBACK TRANSACTION

	END CATCH

	DROP TABLE #CSV_Medico
	SET NOCOUNT OFF;

GO


CREATE OR ALTER PROC spHospital.ArchivoMedico @rutaCSV NVARCHAR(500)
AS
	SET NOCOUNT ON;
	IF OBJECT_ID('tempdb..#CSVMedico') IS NOT NULL
	CREATE TABLE #CSVMedico (
		nombre VARCHAR(30) NOT NULL,
		apellido VARCHAR(30) NOT NULL,
		especialidad VARCHAR(50) NOT NULL,
		nroColegiado VARCHAR(8) NOT NULL,
		)

	-- Declarar variables
	DECLARE @INSERCCION AS NVARCHAR(MAX)
		, @mensaje AS VARCHAR(250)
		, @cant AS INT;
	
	-- Insertar valores del csv en la tabla temporal
	SET @INSERCCION = N'BULK INSERT #CSVMedico FROM ''' + @rutaCSV + N''' WITH(CHECK_CONSTRAINTS, CODEPAGE = ''65001'', FIRSTROW = 2, FIELDTERMINATOR = '';'')'
	BEGIN TRY
		BEGIN TRANSACTION
		
		EXEC sp_executesql @INSERCCION

		-- TRANSFORMACION DE DATOS
		UPDATE #csvMedico
		SET especialidad = UPPER(especialidad) --es necesario? no tenemos ninguna condicion que nos oblige
		
		UPDATE #csvMedico
		SET nombre = UPPER(nombre) --es necesario? no tenemos ninguna condicion que nos oblige

		INSERT INTO dbHospital.medico (id_especialidad_medico,id_medico,nombre,apellido,nroMatricula)
		SELECT x.id,
		a.nombre, a.apellido,a.nroColegiado
		from #CSVMedico m join dbHospital.especialidad x on a.especialidad=x.nombre
		WHERE NOT EXIST ( SELECT 1 FROM dbHospital.medico b
		where m.nroColegiado=b.nroMatricula
		) --Problema, de donde saco el id medico? lo hacemos identity?
		
		SET @cant = @@ROWCOUNT;

		SET @mensaje = 'La tabla de medicos ha recibido' + CAST(@cant AS varchar) + ' registros nuevos';
		PRINT @mensaje;

		--EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'   es requisito documentar esto?

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		PRINT 'Error en la carga de medicos'
		PRINT 'Linea: ' + ERROR_LINE() + ' - Error: ' + ERROR_MESSAGE()
		
		IF @@TRANCOUNT > 0
		--variable del sistema, indica si hay una transaccion activa 
			ROLLBACK TRANSACTION

	END CATCH

	DROP TABLE #CSVMedico
	SET NOCOUNT OFF;

GO


CREATE OR ALTER PROC spHospital.ArchivoSede @rutaCSV NVARCHAR(500)
AS
	SET NOCOUNT ON;
	IF OBJECT_ID('tempdb..#CSV_Sede') IS NOT NULL
	CREATE TABLE #CSV_Sede (
		Sede VARCHAR(30) NOT NULL,
		Direccion VARCHAR(50) NOT NULL,
		Localidad VARCHAR(30) NOT NULL,
		Provincia VARCHAR(30) NOT NULL,
		)

	-- Declarar variables
	DECLARE @INSERCCION AS NVARCHAR(MAX)
		, @mensaje AS VARCHAR(250)
		, @cant AS INT;
	
	-- Insertar valores del csv en la tabla temporal
	SET @INSERCCION = N'BULK INSERT #CSV_Sede FROM ''' + @rutaCSV + N''' WITH(CHECK_CONSTRAINTS, CODEPAGE = ''65001'', FIRSTROW = 2, FIELDTERMINATOR = '';'')'
	BEGIN TRY
		BEGIN TRANSACTION
		
		EXEC sp_executesql @INSERCCION

		-- TRANSFORMACION DE DATOS
		--sede solo posee 3 campos, id;nombre;direccion. Voy a tener que modificar los datos para poder insertalos correctamente en la tabla
		UPDATE #CSV_Sede
		SET Dieccion = Direccion + ',' + Localidad + ',' + Provincia
		
		
		INSERT INTO dbHospital.sedeDeAtencion (nombreDeSede,direccionSede) --y id como hago?, como direccion es sumatoria voy a aumentar campo original
		SELECT a.Sede,a.Direccion
		from #CSVSedes a 
		WHERE NOT EXIST ( SELECT 1 FROM dbHospital.sedeDeAtencion b
		where a.Sede=b.nombreDeSede and a.Direccion = b.direccionSede
		)
		SET @cant = @@ROWCOUNT;

		SET @mensaje = 'La tabla de sedes ha recibido ' + CAST(@cant AS varchar) + ' sedes nuevas';
		PRINT @mensaje;

		--EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'   es requisito documentar esto?

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		PRINT 'Error en la carga de sedes'
		PRINT 'Linea: ' + ERROR_LINE() + ' - Error: ' + ERROR_MESSAGE()
		
		IF @@TRANCOUNT > 0
		--variable del sistema, indica si hay una transaccion activa 
			ROLLBACK TRANSACTION

	END CATCH

	DROP TABLE #CSV_Sede
	SET NOCOUNT OFF;

GO


CREATE OR ALTER PROC spHospital.ArchivoPrestador @rutaCSV NVARCHAR(500)
AS
	SET NOCOUNT ON;
	IF OBJECT_ID('tempdb..#CSV_Prestador') IS NOT NULL
	CREATE TABLE #CSV_Prestador (
		Prestador VARCHAR(20) NOT NULL,
		Plann VARCHAR(50) NOT NULL --plan es una instruccion
		)

	-- Declarar variables
	DECLARE @INSERCCION AS NVARCHAR(MAX)
		, @mensaje AS VARCHAR(250)
		, @cant AS INT;
	
	-- Insertar valores del csv en la tabla temporal
	SET @INSERCCION = N'BULK INSERT #CSV_Prestador FROM ''' + @rutaCSV + N''' WITH(CHECK_CONSTRAINTS, CODEPAGE = ''65001'', FIRSTROW = 2, FIELDTERMINATOR = '';'')'
	BEGIN TRY
		BEGIN TRANSACTION
		
		EXEC sp_executesql @INSERCCION

		INSERT INTO dbHospital.prestador (nombrePrestador,planPrestador,activo)--y el id prestador y idcobertura?
		SELECT a.Prestador,a.Plann
		from #CSV_Prestador a 
		WHERE NOT EXIST ( SELECT 1 FROM dbHospital.prestador b
		where a.Prestador=b.nombrePrestador and a.Plann=b.planPrestador
		)
		SET @cant = @@ROWCOUNT;

		SET @mensaje = 'La tabla prestador ha recibido' + CAST(@cant AS varchar) + ' prestadores y/o planes nuevos';
		PRINT @mensaje;

		--EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'   es requisito documentar esto?

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		PRINT 'Error en la carga de prestadores y/o planes'
		PRINT 'Linea: ' + ERROR_LINE() + ' - Error: ' + ERROR_MESSAGE()
		
		IF @@TRANCOUNT > 0
		--variable del sistema, indica si hay una transaccion activa 
			ROLLBACK TRANSACTION

	END CATCH

	DROP TABLE #CSV_Prestador
	SET NOCOUNT OFF;

GO

--luego hace un sp para usuarios, no le veo sentido colocarlo antes de pacientes...

CREATE OR ALTER PROC spHospital.ArchivoPacientes @rutaCSV NVARCHAR(500)
AS
	SET NOCOUNT ON;
	IF OBJECT_ID('tempdb..#CSV_Pacientes') IS NOT NULL
	CREATE TABLE #CSV_Pacientes (
		Nombre VARCHAR(20) NOT NULL,
		Apellido VARCHAR(20) NOT NULL,
		FechaNacimiento DATE NOT NULL, --EN ARCHIVO LO TOMAN COMO VARCHAR Y LUEGO LO CONVIERTEN...
		TipoDocumento varchar (15) NOT NULL, --no asumo que solo va a ser dni, sino char(3)
		NroDocumento varchar (8) NOT NULL, --no se si sera un dni con 7 digitos u 8, sino char, en archivo los dni no tienen punto
		Sexo varchar (1) NOT NULL, --gaurdo solo la primera letra M o F, ajustar check de la tabla para que concuerde
		Genero varchar (1) NOT NULL, --guardo solo primera letra, Mujer y Hombre, ajustar check
		TelefonoFijo char(14) NOT NULL,
		Nacionalidad varchar (20) NOT NULL,
		Mail varchar (30) NOT NULL,
		Calle_y_nro varchar(30) NOT NULL,
		Localidad varchar (30) NOT NULL,
		Provincia varchar (20) NOT NULL,
		)

	-- Declarar variables
	DECLARE @INSERCCION AS NVARCHAR(MAX)
		, @mensaje AS VARCHAR(250)
		, @cant AS INT;
	
	-- Insertar valores del csv en la tabla temporal
	SET @INSERCCION = N'BULK INSERT #CSV_Pacientes FROM ''' + @rutaCSV + N''' WITH(CHECK_CONSTRAINTS, CODEPAGE = ''65001'', FIRSTROW = 2, FIELDTERMINATOR = '';'')'
	BEGIN TRY
		BEGIN TRANSACTION
		
		EXEC sp_executesql @INSERCCION

		INSERT INTO dbHospital.paciente (nombre,apellido,fechaNacimiento,tipoDoc,numDoc,sexoBio,genero,telFijo,nacionalidad,mail)--y el id paciente? tiene identity, no deberia dar problema al momento de insertar no?
		SELECT a.Nombre,a.Apellido,a.FechaNacimiento,a.TipoDocumento,a.NroDocumento,
		a.Sexo,a.Genero,a.TelefonoFijo,a.Nacionalidad,a.Mail
		from #CSV_Paciente a 
		WHERE NOT EXIST ( SELECT 1 FROM dbHospital.paciente b
		where a.NroDocumento=b.numDoc)
		SET @cant = @@ROWCOUNT;

		SET @mensaje = 'La tabla pacientes ha recibido' + CAST(@cant AS varchar) + ' pacientes nuevos';
		PRINT @mensaje;

		--EXEC spCureSA.InsertarLog @texto = @ilog, @modulo = '[INSERT]'   es requisito documentar esto?

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		PRINT 'Error en la carga de pacientes'
		PRINT 'Linea: ' + ERROR_LINE() + ' - Error: ' + ERROR_MESSAGE()
		
		IF @@TRANCOUNT > 0
		--variable del sistema, indica si hay una transaccion activa 
			ROLLBACK TRANSACTION

	END CATCH

	DROP TABLE #CSV_Pacientes
	SET NOCOUNT OFF;

GO

--****FALTA STORE PROCEDURE PARA DOMICILIO, PARA CREACION DE USUARIOS SI ENCUENTRA PACIENTES SIN UNO
--TMB ARCHIVO JSON PARA AUTORIZACION Y LO QUE LE SIGUE DESPUES

