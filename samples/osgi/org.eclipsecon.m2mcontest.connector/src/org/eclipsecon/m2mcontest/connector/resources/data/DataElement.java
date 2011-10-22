/*******************************************************************************
 * Copyright (c) 2011 Sierra Wireless All rights reserved. This program and the
 * accompanying materials are made available under the terms of the Eclipse
 * Public License v1.0 which accompanies this distribution, and is available at
 * http://www.eclipse.org/legal/epl-v10.html
 *
 * Contributors: Benjamin Cabé (Sierra Wireless) - initial API and
 * implementation
 *******************************************************************************/
package org.eclipsecon.m2mcontest.connector.resources.data;

import java.util.Date;

import javax.xml.bind.annotation.XmlElement;
import javax.xml.bind.annotation.XmlRootElement;

import org.eclipsecon.m2mcontest.connector.resources.OID;

@XmlRootElement
public class DataElement {
	@XmlElement(name = "_id")
	public OID _id;
	public String sensor;
	public Float value;

	public Date getAcquisitionDate() {
		return new Date(Long.valueOf(_id.oid.substring(0, 8), 16) * 1000);
	}
}
