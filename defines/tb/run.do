if [file exists work] {vdel -all}
vlib work
vlog +incdir+../src/ -f files.f
onbreak {resume}
set NoQuitOnFinish 1
vsim -voptargs=+acc work.ff_d 
#do wave.do
run 130ms
