class Vector {
	constructor(x, y, z) {
		this.x = x ?? 0;
		this.y = y ?? 0;
		this.z = z ?? 0;
	}

	// Adds another vector to this vector
	add(vector) {
		return new Vector(this.x + vector.x, this.y + vector.y, this.z + vector.z);
	}

	// Subtracts another vector from this vector
	subtract(vector) {
		return new Vector(this.x - vector.x, this.y - vector.y, this.z - vector.z);
	}

	// Multiplies this vector by a scalar
	scalarMultiply(scalar) {
		return new Vector(this.x * scalar, this.y * scalar, this.z * scalar);
	}

	// Calculates the dot product of this vector and another vector
	dot(vector) {
		return this.x * vector.x + this.y * vector.y + this.z * vector.z;
	}

	// Calculates the cross product of this vector and another vector
	cross(vector) {
		return new Vector(
			this.y * vector.z - this.z * vector.y,
			this.z * vector.x - this.x * vector.z,
			this.x * vector.y - this.y * vector.x
		);
	}

	// Calculates the magnitude (length) of this vector
	magnitude() {
		return Math.sqrt(this.x * this.x + this.y * this.y + this.z * this.z);
	}

	// Normalizes this vector
	normalize() {
		const mag = this.magnitude();
		if (mag === 0)
			return new Vector(0, 0, 0);
		return this.scalarMultiply(1 / mag);
	}
}

Vector.from = object => {
	const toNum = x => typeof x === 'number' ? x : 0;

	return new Vector(toNum(object.x), toNum(object.y), toNum(object.z));
}
