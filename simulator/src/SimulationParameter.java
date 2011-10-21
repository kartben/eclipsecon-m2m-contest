/*******************************************************************************
 * Copyright (c) 2011 Sierra Wireless All rights reserved. This program and the
 * accompanying materials are made available under the terms of the Eclipse
 * Public License v1.0 which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors: Benjamin Cabé (Sierra Wireless) - initial API and
 * implementation
 *******************************************************************************/
import java.util.Random;

public class SimulationParameter {
	private int min;
	private int max;
	private int inc;
	private int currentValue;

	private byte ascending = 1;

	public SimulationParameter(int min, int max, int inc) {
		super();
		this.min = min;
		this.max = max;
		this.inc = inc;
		this.currentValue = min;
	}

	/**
	 * Update currentValue according to the simulation policy
	 * 
	 * @return the updated currentValue
	 */
	public int updateValue() {
		Random r = new Random();
		int random = r.nextInt(100);
		// in 75% of the cases, we follow the "direction" direction to
		// increment/decrement current value
		if (random <= 75) {
			currentValue += inc * ascending;
		} else {
			currentValue -= inc * ascending;
		}

		if (currentValue < min) {
			currentValue = min;
			if (ascending == -1)
				ascending = 1;
		}
		if (currentValue > max) {
			currentValue = max;
			if (ascending == 1)
				ascending = -1;
		}

		return currentValue;
	}
}
