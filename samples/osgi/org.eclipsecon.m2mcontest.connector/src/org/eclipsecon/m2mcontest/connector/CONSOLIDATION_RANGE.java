/*******************************************************************************
 * Copyright (c) 2011 Sierra Wireless All rights reserved. This program and the
 * accompanying materials are made available under the terms of the Eclipse
 * Public License v1.0 which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors: Benjamin Cabé (Sierra Wireless) - initial API and
 * implementation
 *******************************************************************************/
package org.eclipsecon.m2mcontest.connector;

public enum CONSOLIDATION_RANGE {
	ONE_MIN("OneMinute"), FIVE_MIN("FiveMinute"), ONE_HOUR("OneHour");

	public String collectionSuffix;

	private CONSOLIDATION_RANGE(String suffix) {
		collectionSuffix = suffix;
	}
}
