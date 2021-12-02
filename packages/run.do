if [file exists work] {vdel -all}
vlib work
vlog +define+first_block +define+second_nest -f files.f
onbreak {resume}
set NoQuitOnFinish 1
vsim -voptargs=+acc work.test 
#do wave.do
run 130ms
