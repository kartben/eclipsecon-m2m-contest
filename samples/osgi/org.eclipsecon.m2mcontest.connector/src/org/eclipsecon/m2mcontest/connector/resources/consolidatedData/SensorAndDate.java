/*******************************************************************************
 * Copyright (c) 2011 Sierra Wireless All rights reserved. This program and the
 * accompanying materials are made available under the terms of the Eclipse
 * Public License v1.0 which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors: Benjamin Cabé (Sierra Wireless) - initial API and
 * implementation
 *******************************************************************************/
package org.eclipsecon.m2mcontest.connector.resources.consolidatedData;

import javax.xml.bind.annotation.XmlElement;

import org.eclipsecon.m2mcontest.connector.resources.MongoDate;

public class SensorAndDate {
	public String sensorId;
	@XmlElement(name = "ts")
	public MongoDate when;
}