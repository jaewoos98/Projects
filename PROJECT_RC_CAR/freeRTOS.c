/* Includes ------------------------------------------------------------------*/
#include "FreeRTOS.h"
#include "task.h"
#include "main.h"
#include "cmsis_os.h"

/* Private includes ----------------------------------------------------------*/
/* USER CODE BEGIN Includes */

/* USER CODE END Includes */

/* Private typedef -----------------------------------------------------------*/
/* USER CODE BEGIN PTD */

/* USER CODE END PTD */

/* Private define ------------------------------------------------------------*/
/* USER CODE BEGIN PD */
extern uint8_t txData[8];
uint8_t direction;
uint8_t ledValue;
/* USER CODE END PD */

/* Private macro -------------------------------------------------------------*/
/* USER CODE BEGIN PM */
void Go(void)
{
	HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, 0);
	HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, 1);
	HAL_GPIO_WritePin(GPIOA, GPIO_PIN_7, 0);
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_6, 1);
}
void Back(void)
{
	HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, 1);
	HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, 0);
	HAL_GPIO_WritePin(GPIOA, GPIO_PIN_7, 1);
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_6, 0);
}

void forward(void)
{
	TIM3->CCR1 = 1000;
	TIM3->CCR2 = 1000;
	Go();
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_13, 0);
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_14, 0);
}

void backward(void)
{
	TIM3->CCR1 = 400;
	TIM3->CCR2 = 400;
	Back();
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_13, 1);
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_14, 1);
}

void left(void)
{
	TIM3->CCR1 = 200;
	TIM3->CCR2 = 1000-1;
	Go();
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_13, 0);
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_14, 0);
}

void right(void)
{
	TIM3->CCR1 = 1000-1;
	TIM3->CCR2 = 200;
	Go();
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_13, 0);
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_14, 0);
}

void stop(void)
{
	HAL_GPIO_WritePin(GPIOA, GPIO_PIN_5, 0);	// PA5
	HAL_GPIO_WritePin(GPIOA, GPIO_PIN_6, 0);	// PA6
	HAL_GPIO_WritePin(GPIOA, GPIO_PIN_7, 0);	// PA7
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_6, 0);	// PB1
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_13, 0);
	HAL_GPIO_WritePin(GPIOB, GPIO_PIN_14, 0);
}

void Emergencylight(void)
{
	HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_8);
	HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_9);
	HAL_Delay(300);
}

void Rightlight(void)
{
	HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_9);
	HAL_Delay(300);
}

void Leftlight(void)
{
	HAL_GPIO_TogglePin(GPIOB, GPIO_PIN_8);
	HAL_Delay(300);

}
/* USER CODE END PM */

/* Private variables ---------------------------------------------------------*/
/* USER CODE BEGIN Variables */



/* USER CODE END Variables */
/* Definitions for defaultTask */
osThreadId_t defaultTaskHandle;
const osThreadAttr_t defaultTask_attributes = {
  .name = "defaultTask",
  .stack_size = 128 * 4,
  .priority = (osPriority_t) osPriorityNormal,
};
/* Definitions for Handle */
osThreadId_t HandleHandle;
const osThreadAttr_t Handle_attributes = {
  .name = "Handle",
  .stack_size = 128 * 4,
  .priority = (osPriority_t) osPriorityNormal,
};
/* Definitions for LED */
osThreadId_t LEDHandle;
const osThreadAttr_t LED_attributes = {
  .name = "LED",
  .stack_size = 128 * 4,
  .priority = (osPriority_t) osPriorityNormal,
};

/* Private function prototypes -----------------------------------------------*/
/* USER CODE BEGIN FunctionPrototypes */

/* USER CODE END FunctionPrototypes */

void StartDefaultTask(void *argument);
void StartTask02(void *argument);
void StartTask03(void *argument);

void MX_FREERTOS_Init(void); /* (MISRA C 2004 rule 8.1) */

/**
  * @brief  FreeRTOS initialization
  * @param  None
  * @retval None
  */
void MX_FREERTOS_Init(void) {
  /* USER CODE BEGIN Init */

  /* USER CODE END Init */

  /* USER CODE BEGIN RTOS_MUTEX */
  /* add mutexes, ... */
  /* USER CODE END RTOS_MUTEX */

  /* USER CODE BEGIN RTOS_SEMAPHORES */
  /* add semaphores, ... */
  /* USER CODE END RTOS_SEMAPHORES */

  /* USER CODE BEGIN RTOS_TIMERS */
  /* start timers, add new ones, ... */
  /* USER CODE END RTOS_TIMERS */

  /* USER CODE BEGIN RTOS_QUEUES */
  /* add queues, ... */
  /* USER CODE END RTOS_QUEUES */

  /* Create the thread(s) */
  /* creation of defaultTask */
  defaultTaskHandle = osThreadNew(StartDefaultTask, NULL, &defaultTask_attributes);

  /* creation of Handle */
  HandleHandle = osThreadNew(StartTask02, NULL, &Handle_attributes);

  /* creation of LED */
  LEDHandle = osThreadNew(StartTask03, NULL, &LED_attributes);

  /* USER CODE BEGIN RTOS_THREADS */
  /* add threads, ... */
  /* USER CODE END RTOS_THREADS */

  /* USER CODE BEGIN RTOS_EVENTS */
  /* add events, ... */
  /* USER CODE END RTOS_EVENTS */

}

/* USER CODE BEGIN Header_StartDefaultTask */
/**
  * @brief  Function implementing the defaultTask thread.
  * @param  argument: Not used
  * @retval None
  */
/* USER CODE END Header_StartDefaultTask */
void StartDefaultTask(void *argument)
{
  /* USER CODE BEGIN StartDefaultTask */
  /* Infinite loop */
  for(;;)
  {
    osDelay(1);
  }
  /* USER CODE END StartDefaultTask */
}

/* USER CODE BEGIN Header_StartTask02 */
/**
* @brief Function implementing the Handle thread.
* @param argument: Not used
* @retval None
*/
/* USER CODE END Header_StartTask02 */
void StartTask02(void *argument)
{
  /* USER CODE BEGIN StartTask02 */
  /* Infinite loop */
  for(;;)
  {
	  if(txData[6] == 0 || txData[6] == 1 || txData[6] == 2 || txData[6] == 4 || txData[6] == 8)
	  {
		  direction = txData[6];
		  switch(direction)
		  {
			  case 0 :
				  stop();
				  break;
			  case 1 :
				  forward();
				  break;
			  case 2 :
				  backward();
				  break;
			  case 4 :
				  left();
				  break;
			  case 8 :
				  right();
				  break;
			  default : break;
		  }
	  }
	  osDelay(1);
  }
  /* USER CODE END StartTask02 */
}

/* USER CODE BEGIN Header_StartTask03 */
/**
* @brief Function implementing the LED thread.
* @param argument: Not used
* @retval None
*/
/* USER CODE END Header_StartTask03 */
void StartTask03(void *argument)
{
  /* USER CODE BEGIN StartTask03 */
  /* Infinite loop */
	TIM3->PSC = 2000-1;	// basic setting 1000(100hz) / prescaler
	/* USER CODE BEGIN StartTask02 */
	/* Infinite loop */
	for(;;)
	{
		if(txData[5] == 4 ||txData[5] == 8 || txData[5] == 16 || txData[5] == 32)
		{
			ledValue = txData[5];
			switch(ledValue)
			{
				case 4 :
					while(1)
					{
						Emergencylight();
						if(txData[5] == 16)
						{
							HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, 0);
							HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, 0);
							break;
						}
					}
				    break;
				case 8 :
					while(1)
					{
						Rightlight();
						if(txData[6] == 1)
						{
							HAL_GPIO_WritePin(GPIOB, GPIO_PIN_9, 0);
							break;
						}
					}
					break;
				case 32 :
					while(1)
					{
						Leftlight();
						if(txData[6] == 1)
						{
							HAL_GPIO_WritePin(GPIOB, GPIO_PIN_8, 0);
							break;
						}
					}
				default : break;
			}
		}
    osDelay(1);
	}
  /* USER CODE END StartTask03 */
}

/* Private application code --------------------------------------------------*/
/* USER CODE BEGIN Application */

/* USER CODE END Application */

