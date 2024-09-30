# ��� Ŀ�̼Ŵ� ������Ʈ

�� ������Ʈ�� ����ũ����Ʈ�ѷ��� �̱� ���� ��ǻ�͸� Ȱ���Ͽ� ����� �����ϰ� �����͸� �����ϴ� �������� �ý����Դϴ�. �� �ý����� ������ ���� ����, �ǽð� ������ ����, ���� ó�� ����� �����Ͽ� �پ��� ��� ���� �о߿� ������ �� �ֽ��ϴ�.

## ���� ���

- **����ũ����Ʈ�ѷ�**: ���� ����ũ����Ʈ�ѷ� ���带 ����Ͽ� ����� ���͸� �����ϰ� �����ϰ� �پ��� �����κ��� �����͸� �����մϴ�. �� ����� IMU(���� ���� ��ġ), ��а�, GPS �� �پ��� ������ ���յǾ� ����� �������� ������ �����ϰ� �մϴ�.

- **�̱� ���� ��ǻ��**: ���� �̱� ���� ��ǻ�͸� ����Ͽ� ������ ������ ó��, ���� �м�, ��� ���� ���� �����մϴ�. �� ��ǻ�ʹ� �ǽð� ���� ��Ʈ����, ���� ���� �˰��� ����, ���� ���� �������̽� ���� �� �پ��� ��� ����� �����մϴ�.

## �ֿ� ���

1. **���� ���� ����**: PID ���� �˰����� ����Ͽ� �������̰� ��Ȯ�� ��� ������ �����մϴ�.
2. **�ǽð� ������ ����**: �پ��� �����κ��� ���� �����͸� �ǽð����� �����ϰ� �м��մϴ�.
3. **���� ó�� �� �м�**: ���ػ� ī�޶� ���� �ǽð� ������ �Կ��ϰ� ó���Ͽ� ��ü �ν�, ��� ��ȹ � Ȱ���մϴ�.
4. **���� ����͸� �� ����**: �� ��� �������̽��� ���� ����� ���¸� �ǽð����� ����͸��ϰ� �������� ������ �� �ֽ��ϴ�.
5. **���� ���� ���**: GPS �����Ϳ� ���� ������ Ȱ���Ͽ� ���� ���α׷��ֵ� ��θ� �ڵ����� ������ �� �ֽ��ϴ�.
6. **������ �α� �� �м�**: ���� �� ������ ��� �����͸� �����ϰ� ��ó�� �м��� ���� ������ �����մϴ�.

## ���� ����

- arduino_code/
  - drone_controller/
    - drone_controller.ino: ����ũ����Ʈ�ѷ��� ���� �ڵ�
    - sensor_module.h: ���� ������ ó���� ���� ��� ����
    - motor_control.h: ���� ���� ���� �Լ����� ������ ��� ����
    - pid_controller.h: PID ���� �˰��� ����
- raspberry_pi_code/
  - main.py: �̱� ���� ��ǻ���� ���� ���� ����
  - drone_comm.py: ��а��� ����� �����ϴ� ���
  - camera_module.py: ī�޶� ���� �� ���� ó�� ���
  - flight_controller.py: ���� ���� �˰��� ����
  - data_logger.py: ���� ������ �α� �� �м� ���
  - web_interface/: �� ��� ����͸� �� ���� �������̽�

## ��ġ �� ����

(��ġ �� ���� ����� ���� ���� �ȳ��� ���⿡ �߰�)

## ��� ���

(�ý��� ��� ����� ���� �ܰ躰 ���̵带 ���⿡ �߰�)

## �⿩ ���

(������Ʈ�� �⿩�ϴ� ���, �ڵ� ��Ÿ�� ���̵�, Ǯ ������Ʈ ���μ��� ���� ����)

## ���̼���

�� ������Ʈ�� MIT ���̼��� �Ͽ� �����˴ϴ�. �ڼ��� ������ LICENSE ������ �����ϼ���.

## ����ó

������Ʈ�� ���� �����̳� ���Ȼ����� �����ø� [gnt8521@gmail.com]�� �����ֽñ� �ٶ��ϴ�.

# Drone Commissioning Project

This project is a comprehensive system that utilizes microcontrollers and single-board computers to control drones and collect data. The system integrates precise flight control, real-time data collection, and video processing capabilities, making it applicable to a wide range of drone applications.

## Components

- **Microcontroller**: A high-performance microcontroller board is used to precisely control the drone's motors and collect data from various sensors. This board is integrated with a variety of sensors such as IMU (Inertial Measurement Unit), barometer, GPS, etc., enabling stable flight of the drone.

- **Single Board Computer**: A powerful single-board computer is used to perform complex data processing, video analysis, and communication management. This computer supports various advanced functions such as real-time video streaming, execution of autonomous flight algorithms, and provision of remote control interfaces.

## Key Features

1. **Precise Flight Control**: Implements stable and accurate drone flight using PID control algorithms.
2. **Real-time Data Collection**: Collects and analyzes flight data from various sensors in real-time.
3. **Video Processing and Analysis**: Captures and processes real-time video through a high-resolution camera, utilized for object recognition, path planning, etc.
4. **Remote Monitoring and Control**: Allows real-time monitoring of the drone's status and remote control through a web-based interface.
5. **Autonomous Flight Capability**: Can automatically fly pre-programmed routes using GPS data and sensor information.
6. **Data Logging and Analysis**: Stores all data collected during flight and provides tools for post-processing analysis.

## File Structure

- arduino_code/
  - drone_controller/
    - drone_controller.ino: Main code for the microcontroller
    - sensor_module.h: Header file for sensor data processing
    - motor_control.h: Header file containing motor control functions
    - pid_controller.h: Implementation of PID control algorithm
- raspberry_pi_code/
  - main.py: Main execution file for the single-board computer
  - drone_comm.py: Module managing communication with the drone
  - camera_module.py: Camera control and video processing module
  - flight_controller.py: Implementation of flight control algorithms
  - data_logger.py: Module for sensor data logging and analysis
  - web_interface/: Web-based monitoring and control interface

## Installation and Setup

(Add detailed instructions for installation and setup here)

## Usage

(Add a step-by-step guide on how to use the system here)

## How to Contribute

(Explain how to contribute to the project, code style guide, pull request process, etc.)

## License

This project is distributed under the MIT License. See the LICENSE file for more details.

## Contact

If you have any questions or suggestions about the project, please contact us at [gnt8521@gmail.com].