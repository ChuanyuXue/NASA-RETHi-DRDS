package server

import (
	"encoding/json"
	"errors"
	"fmt"
	"net/http"
	"os/exec"

	"github.com/AmyangXYZ/sgo"
	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	CheckOrigin:     func(r *http.Request) bool { return true },
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

type PyFuncParams struct {
	CurrentTime            float64 `json:"current_time"`
	CurrentTemperature     float64 `json:"current_temperature"`
	BatteryStateOfCharge   float64 `json:"battery_state_of_charge"`
	CurrentHVACMode        string  `json:"current_hvac_mode"`
	CurrentHeatingSetpoint float64 `json:"current_heating_setpoint"`
	CurrentCoolingSetpoint float64 `json:"current_cooling_setpoint"`
	TimeOfNewSetPoint      float64 `json:"time_of_new_setpoint"`
	NewHVACMode            string  `json:"new_hvac_mode"`
	NewHeatingSetpoint     float64 `json:"new_heating_setpoint"`
	NewCoolingSetpoint     float64 `json:"new_cooling_setpoint"`
	FinalTime              float64 `json:"final_time"`
	NumTimeSteps           float64 `json:"num_time_steps"`
	NumSamples             float64 `json:"num_samples"`
}

type PyFuncOutput struct {
	Ts            []float64   `json:"ts"`
	Temperatures  [][]float64 `json:"temperatures"`
	HVACPower     [][]float64 `json:"hvac_power"`
	BatteryCharge [][]float64 `json:"battery_charge"`
	Quantiles     struct {
		Temperature struct {
			Median []float64 `json:"median"`
			Lower  []float64 `json:"lower"`
			Upper  []float64 `json:"upper"`
		} `json:"temperature"`
		BatteryCharge struct {
			Median []float64 `json:"median"`
			Lower  []float64 `json:"lower"`
			Upper  []float64 `json:"upper"`
		} `json:"battery_charge"`
		HVACPower struct {
			Median []float64 `json:"median"`
			Lower  []float64 `json:"lower"`
			Upper  []float64 `json:"upper"`
		} `json:"hvac_power"`
	} `json:"quantiles"`
}

func CDCM(ctx *sgo.Context) error {
	ws, err := upgrader.Upgrade(ctx.Resp, ctx.Req, nil)
	exitSig := make(chan bool)
	if err != nil {
		return err
	}
	fmt.Println("ws/comm connected")
	defer func() {
		ws.Close()
		fmt.Println("ws/comm client closed")
	}()
	go func() {
		for {
			_, p, err := ws.ReadMessage()
			if err != nil {
				exitSig <- true
			} else {
				params := PyFuncParams{}
				err = json.Unmarshal(p, &params)
				if err != nil {
					fmt.Println(err)
					exitSig <- true
				}
				output, err := call(params)
				if err != nil {
					fmt.Println(err)
					exitSig <- true
				} else {
					ws.WriteJSON(output)
				}

			}
		}
	}()

	<-exitSig
	return errors.New("stop ws")

}

func call(params PyFuncParams) (PyFuncOutput, error) {
	output := PyFuncOutput{}
	inputJSON, _ := json.Marshal(params)
	fmt.Println(string(inputJSON))
	outputJSON, err := exec.Command("python3", "-u", "/utils/cdcm/cdcm_hab/examples/HCI_CDCM_DT/thermal_dt_script.py", string(inputJSON)).Output()
	if err != nil {
		return output, err
	}
	// fmt.Println(string(outputJSON))
	err = json.Unmarshal(outputJSON, &output)
	if err != nil {
		fmt.Println(err)
		return output, err
	}
	return output, nil
}
