module GLTools

import GLFW
using ModernGL

# http://www.opengl.org/wiki/Program_Introspection#Uniforms_and_blocks

# immutable ShaderUniform
#     function new(program, name)
#         uniform = glGetUniformLocation(program, name)
#         @assert uniform > -1
#     end
# end

# tex = ShaderUniform("tex")
# set!(tex, 4) # Should assert the value is of the wrong type
# get(tex)

function renderloop(window, frame, clearcolor=(0.0, 0.0, 0.0, 1.0), clearbits=GL_COLOR_BUFFER_BIT)
	while !GLFW.WindowShouldClose(window)   
		glClearColor(clearcolor[1], clearcolor[2], clearcolor[3], clearcolor[4])
		glClear(clearbits)
		frame()
		GLFW.SwapBuffers(window)
		GLFW.PollEvents()
	end
end


function createwindow(width, height, title="OpenGL Window")
	# OS X-specific GLFW hints to initialize the correct version of OpenGL
	@osx_only begin
	    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MAJOR, 3)
	    GLFW.WindowHint(GLFW.CONTEXT_VERSION_MINOR, 2)
	    GLFW.WindowHint(GLFW.OPENGL_PROFILE, GLFW.OPENGL_CORE_PROFILE)
	    GLFW.WindowHint(GLFW.OPENGL_FORWARD_COMPAT, GL_TRUE)
	end
	 
	window = GLFW.CreateWindow(width, height, title)
	GLFW.MakeContextCurrent(window)

	window
end

function glGenOne(glGenFn)
    id::Ptr{GLuint} = GLuint[0]
    glGenFn(1, id)
    glCheckError("generating a buffer, array, or texture")
    unsafe_load(id)
end
glGenBuffer() = glGenOne(glGenBuffers)
glGenVertexArray() =  glGenOne(glGenVertexArrays)
glGenTexture() =  glGenOne(glGenTextures)
glGenRenderbuffer() =  glGenOne(glGenRenderbuffers)

#= TODO:
function glwith(f, vao=nothing, vbo=nothing, program=nothing)
	vao != nothing &&
end
function glwith(f, bindtype, bindfn, obj)
    prev::Ptr{GLuint} = GLuint[0]
	glGetIntegerv(bindtype, prev)
	bindfn(bindarg, obj)
	f()
	# prev will either be a buffer object name, in which case 
	# the call will rebind that buffer, or it will be zero, in which
	# case the buffer will be unbound.
	glBindBuffer(bindarg, prev) 
end
=#

function glWithArrayBuffer(f, vbo)
    boundbuf::Ptr{GLuint} = GLuint[0]
	glGetIntegerv(GL_ARRAY_BUFFER_BINDING, boundbuf)
	glBindBuffer(GL_ARRAY_BUFFER, vbo)
	f()
	# boundbuf will either be a buffer object name, in which case 
	# the call will rebind that buffer, or it will be zero, in which
	# case the buffer will be unbound.
	glBindBuffer(GL_ARRAY_BUFFER, boundbuf)
end

function glWithVertexArray(f, vao)
    boundvao::Ptr{GLuint} = GLuint[0]
	glGetIntegerv(GL_VERTEX_ARRAY_BINDING, boundvao)
	glBindVertexArray(vao)
	f()
	glBindVertexArray(boundvao) 
end

function glWithShaderProgram(f, program)
    boundprogram::Ptr{GLuint} = GLuint[0]
	glGetIntegerv(GL_CURRENT_PROGRAM, boundprogram)
	glUseProgram(program)
	f()
	glUseProgram(boundprogram) 
end

function glWithVertexArrayAndArrayBufferAndShaderProgram(f, vao, vbo, program)
	glWithVertexArray(vao) do
		glWithArrayBuffer(vbo) do
			glWithShaderProgram(program) do
				f()
			end
		end
	end	
end

function infolog(obj::GLuint)
	# Return the info log for obj, whether it be a shader or a program.
	isShader = glIsShader(obj)
	getiv   = isShader == GL_TRUE ? glGetShaderiv      : glGetProgramiv
	getInfo = isShader == GL_TRUE ? glGetShaderInfoLog : glGetProgramInfoLog

	# Get the maximum possible length for the descriptive error message
	int::Ptr{GLint} = GLint[0]
	getiv(obj, GL_INFO_LOG_LENGTH, int)
	maxlength = unsafe_load(int)

	# TODO: Create a macro that turns the following into the above:
	# maxlength = @glPointer getiv(obj, GL_INFO_LOG_LENGTH, GLint)

	# Return the text of the message if there is any
	if maxlength > 0
		buffer = zeros(GLchar, maxlength)
		sizei::Ptr{GLsizei} = GLsizei[0]
		getInfo(obj, maxlength, sizei, buffer)
		length = unsafe_load(sizei)
		bytestring(pointer(buffer), length)
	else
		""
	end
end

function validateShader(shader)
	success::Ptr{GLint} = GLint[0]
	glGetShaderiv(shader, GL_COMPILE_STATUS, success)
	unsafe_load(success) == GL_TRUE
end

function glErrorMessage()
	# Return a string representing the current OpenGL error flag, or the empty string if there's no error.
	err = glGetError()
	err == GL_NO_ERROR ? "" :
	err == GL_INVALID_ENUM ? "GL_INVALID_ENUM: An unacceptable value is specified for an enumerated argument. The offending command is ignored and has no other side effect than to set the error flag." :
	err == GL_INVALID_VALUE ? "GL_INVALID_VALUE: A numeric argument is out of range. The offending command is ignored and has no other side effect than to set the error flag." :
	err == GL_INVALID_OPERATION ? "GL_INVALID_OPERATION: The specified operation is not allowed in the current state. The offending command is ignored and has no other side effect than to set the error flag." :
	err == GL_INVALID_FRAMEBUFFER_OPERATION ? "GL_INVALID_FRAMEBUFFER_OPERATION: The framebuffer object is not complete. The offending command is ignored and has no other side effect than to set the error flag." :
	err == GL_OUT_OF_MEMORY ? "GL_OUT_OF_MEMORY: There is not enough memory left to execute the command. The state of the GL is undefined, except for the state of the error flags, after this error is recorded." : "Unknown OpenGL error with error code $err."
end

function glCheckError(actionName="")
	message = glErrorMessage()
	if length(message) > 0
		if length(actionName) > 0
			error("Error ", actionName, ": ", message)
		else
			error("Error: ", message)
		end
	end
end

function createshader(source, typ)
	# Create the shader
	shader = glCreateShader(typ)::GLuint
	if shader == 0
		error("Error creating shader: ", glErrorMessage())
	end

	# Compile the shader
	glShaderSource(shader, 1, convert(Ptr{Uint8}, pointer([convert(Ptr{GLchar}, pointer(source))])), C_NULL)
	glCompileShader(shader)

	# Check for errors
	!validateShader(shader) && error("Shader creation error: ", getInfoLog(shader))
	shader
end

function createshaderprogram(f, vsh::GLuint, fsh::GLuint)
	# Create, link then return a shader program for the given shaders.

	# Create the shader program
	prog = glCreateProgram()
	if prog == 0
		error("Error creating shader program: ", glErrorMessage())
	end

	# Attach the vertex shader
	glAttachShader(prog, vsh)
	glCheckError("attaching vertex shader")

	# Attach the fragment shader
	glAttachShader(prog, fsh)
	glCheckError("attaching fragment shader")
	
	f(prog)
	glCheckError("calling function on shader program before linking")

	# Finally, link the program and check for errors.
	glLinkProgram(prog)
	status::Ptr{GLint} = GLint[0]
	glGetProgramiv(prog, GL_LINK_STATUS, status)
	if unsafe_load(status) == GL_FALSE then
		glDeleteProgram(prog)
		error("Error linking shader: ", glGetInfoLog(prog))
	end

	prog
end
createshaderprogram(vsh::GLuint, fsh::GLuint) =
	createshaderprogram(prog->0, vsh, fsh)
createshaderprogram(vshsource::String, fshsource::String) = createshaderprogram(
	createshader(vshsource, GL_VERTEX_SHADER),
	createshader(fshsource, GL_FRAGMENT_SHADER)
)

function printglinfo()
    println("GLSL version:    ", bytestring(glGetString(GL_SHADING_LANGUAGE_VERSION)))
    println("OpenGL version:  ", bytestring(glGetString(GL_VERSION)))
    println("OpenGL vendor:   ", bytestring(glGetString(GL_VENDOR)))
    println("OpenGL renderer: ", bytestring(glGetString(GL_RENDERER)))
end

end # module
