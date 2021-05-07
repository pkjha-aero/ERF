// Generated by Pankaj Jha on 05/05/2021

#include <RK3.H>

using namespace amrex;

Real
InterpolateCellToFace(
  const int& i, const int& j, const int& k,
  const Array4<Real>& cons_in,
  const int& cons_qty_index,
  const NextOrPrev& nextOrPrev,
  const AdvectionDirection& advectionDirection,
  const int& spatial_order)
{
  /*
   Face index is (i, j, k). This means:
   Coordinates of face (i, j, k) = Coordinates of cell (i-1/2, j    , k    ) for x-dir
   Coordinates of face (i, j, k) = Coordinates of cell (i    , j-1/2, k    ) for y-dir
   Coordinates of face (i, j, k) = Coordinates of cell (i    , j    , k-1/2) for z-dir
  */
  Real interpolatedVal;
  if (nextOrPrev == NextOrPrev::prev) {
    switch (spatial_order) {
      case 2:
        switch (advectionDirection) {
          // q = cons_in(i, j, k, cons_qty_index) = {rho, theta, ...}
          case AdvectionDirection::x: // m = i, q(m-1/2) = q(i-1/2, j    , k    )
            interpolatedVal = 0.5*(cons_in(i, j, k, cons_qty_index) + cons_in(i-1, j, k, cons_qty_index));
            break;
          case AdvectionDirection::y: // m = j, q(m-1/2) = q(i    , j-1/2, k    )
            interpolatedVal = 0.5*(cons_in(i, j, k, cons_qty_index) + cons_in(i, j-1, k, cons_qty_index));
            break;
          case AdvectionDirection::z: // m = k, q(m-1/2) = q(i    , j    , k-1/2)
            interpolatedVal = 0.5*(cons_in(i, j, k, cons_qty_index) + cons_in(i, j, k-1, cons_qty_index));
            break;
          default:
            amrex::Abort("Error: Advection direction is unrecognized");
        }
        break;
      case 4:
        switch (advectionDirection) {
          // q = cons_in(i, j, k, cons_qty_index) = {rho, theta, ...}
          case AdvectionDirection::x: // m = i, q(m-1/2) = q(i-1/2, j    , k    )
            interpolatedVal = (7.0/12.0)*(cons_in(i, j, k, cons_qty_index) + cons_in(i-1, j, k, cons_qty_index))
                             -(1.0/12.0)*(cons_in(i+1, j, k, cons_qty_index) + cons_in(i-2, j, k, cons_qty_index));
            break;
          case AdvectionDirection::y: // m = j, q(m-1/2) = q(i    , j-1/2, k    )
            interpolatedVal = (7.0/12.0)*(cons_in(i, j, k, cons_qty_index) + cons_in(i, j-1, k, cons_qty_index))
                             -(1.0/12.0)*(cons_in(i, j+1, k, cons_qty_index) + cons_in(i, j-2, k, cons_qty_index));
            break;
          case AdvectionDirection::z: // m = k, q(m-1/2) = q(i    , j    , k-1/2)
            interpolatedVal = (7.0/12.0)*(cons_in(i, j, k, cons_qty_index) + cons_in(i, j, k-1, cons_qty_index))
                             -(1.0/12.0)*(cons_in(i, j, k+1, cons_qty_index) + cons_in(i, j, k-2, cons_qty_index));
            break;
          default:
            amrex::Abort("Error: Advection direction is unrecognized");
        }
        break;
      case 6: // In order to make this work cons_in must have indices m-3 and m+2 where m = {i, j, k}
        switch (advectionDirection) {
          // q = cons_in(i, j, k, cons_qty_index) = {rho, theta, ...}
          case AdvectionDirection::x: // m = i, q(m-1/2) = q(i-1/2, j    , k    )
            interpolatedVal = (37.0/60.0)*(cons_in(i, j, k, cons_qty_index) + cons_in(i-1, j, k, cons_qty_index))
                              -(2.0/15.0)*(cons_in(i+1, j, k, cons_qty_index) + cons_in(i-2, j, k, cons_qty_index))
                              +(1.0/60.0)*(cons_in(i+2, j, k, cons_qty_index) + cons_in(i-3, j, k, cons_qty_index));
            break;
          case AdvectionDirection::y: // m = j, q(m-1/2) = q(i    , j-1/2, k    )
            interpolatedVal = (37.0/60.0)*(cons_in(i, j, k, cons_qty_index) + cons_in(i, j-1, k, cons_qty_index))
                              -(2.0/15.0)*(cons_in(i, j+1, k, cons_qty_index) + cons_in(i, j-2, k, cons_qty_index))
                              +(1.0/60.0)*(cons_in(i, j+2, k, cons_qty_index) + cons_in(i, j-3, k, cons_qty_index));
            break;
          case AdvectionDirection::z: // m = k, q(m-1/2) = q(i    , j    , k-1/2)
            interpolatedVal = (37.0/60.0)*(cons_in(i, j, k, cons_qty_index) + cons_in(i, j, k-1, cons_qty_index))
                              -(2.0/15.0)*(cons_in(i, j, k+1, cons_qty_index) + cons_in(i, j, k-2, cons_qty_index))
                              +(1.0/60.0)*(cons_in(i, j, k+2, cons_qty_index) + cons_in(i, j, k-3, cons_qty_index));
            break;
          default:
            amrex::Abort("Error: Advection direction is unrecognized");
        }
        break;
      default:
        amrex::Abort("Error: Spatial order " + std::to_string(spatial_order) + " has not been implemented");
    }
  }
  else {
    amrex::Abort("Error: Interpolation from a cell to a half index next to it has not been implemented");
  }

  return interpolatedVal;
}

Real ComputeAdvectedQuantity(const int &i, const int &j, const int &k,
                             const Array4<Real>& rho_u, const Array4<Real>& rho_v, const Array4<Real>& rho_w,
                             const Array4<Real>& u, const Array4<Real>& v, const Array4<Real>& w,
                             const enum NextOrPrev &nextOrPrev,
                             const enum AdvectedQuantity &advectedQuantity,
                             const enum AdvectingQuantity &advectingQuantity,
                             const int &spatial_order) {
  Real advectingMom = 0.0;
  Real advectedVel = 1.0;
  if (nextOrPrev == NextOrPrev::next) {
    switch(advectedQuantity) {
      case AdvectedQuantity::u:
        switch (advectingQuantity) {
          case AdvectingQuantity::rho_u:
            advectedVel = 1.0; // u(i+1/2,    j, k    )..Needs to be called properly
            advectingMom = 0.5*(rho_u(i+1, j, k) + rho_u(i, j, k));
            break;
          case AdvectingQuantity::rho_v:
            advectedVel = 1.0; // u(i   , j+1/2, k    )..Needs to be called properly
            advectingMom = 0.5*(rho_v(i, j+1, k) + rho_v(i-1, j+1, k));
            break;
          case AdvectingQuantity::rho_w:
            advectedVel = 1.0; // u(i   , j    , k+1/2)..Needs to be called properly
            advectingMom = 0.5*(rho_w(i, j, k+1) + rho_w(i-1, j, k+1));
            break;
          default:
            amrex::Abort("Error: Advecting quantity is unrecognized");
        }
        break;
      case AdvectedQuantity::v:
        switch (advectingQuantity) {
          case AdvectingQuantity::rho_u:
            advectedVel = 1.0; // v(i+1/2,    j, k    )..Needs to be called properly
            advectingMom = 0.5*(rho_u(i+1, j, k) + rho_u(i+1, j-1, k));
            break;
          case AdvectingQuantity::rho_v:
            advectedVel = 1.0; // v(i   , j+1/2, k    )..Needs to be called properly
            advectingMom = 0.5*(rho_v(i, j+1, k) + rho_v(i, j, k));
            break;
          case AdvectingQuantity::rho_w:
            advectedVel = 1.0; // v(i   , j    , k+1/2)..Needs to be called properly
            advectingMom = 0.5*(rho_w(i, j, k+1) + rho_w(i, j-1, k+1));
            break;
          default:
            amrex::Abort("Error: Advecting quantity is unrecognized");
        }
        break;
      case AdvectedQuantity::w:
        switch (advectingQuantity) {
          case AdvectingQuantity::rho_u:
            advectedVel = 1.0; // w(i+1/2,    j, k    )..Needs to be called properly
            advectingMom = 0.5*(rho_u(i+1, j, k) + rho_u(i+1, j, k-1));
            break;
          case AdvectingQuantity::rho_v:
            advectedVel = 1.0; // w(i   , j+1/2, k    )..Needs to be called properly
            advectingMom = 0.5*(rho_v(i, j+1, k) + rho_v(i, j+1, k-1));
            break;
          case AdvectingQuantity::rho_w:
            advectedVel = 1.0; // w(i   , j    , k+1/2)..Needs to be called properly
            advectingMom = 0.5*(rho_w(i, j, k+1) + rho_w(i, j, k));
            break;
          default:
            amrex::Abort("Error: Advecting quantity is unrecognized");
        }
        break;
      default:
        amrex::Abort("Error: Advected quantity is unrecognized");
    }
  }
  else { // nextOrPrev == NextOrPrev::prev
    switch(advectedQuantity) {
      case AdvectedQuantity::u:
        switch (advectingQuantity) {
          case AdvectingQuantity::rho_u:
            advectedVel = 1.0; // u(i-1/2,    j, k    )..Needs to be called properly
            advectingMom = 0.5*(rho_u(i+1, j, k) + rho_u(i, j, k));
            break;
          case AdvectingQuantity::rho_v:
            advectedVel = 1.0; // u(i   , j-1/2, k    )..Needs to be called properly
            advectingMom = 0.5*(rho_v(i, j+1, k) + rho_v(i-1, j+1, k));
            break;
          case AdvectingQuantity::rho_w:
            advectedVel = 1.0; // u(i   , j    , k-1/2)..Needs to be called properly
            advectingMom = 0.5*(rho_w(i, j, k+1) + rho_w(i-1, j, k+1));
            break;
          default:
            amrex::Abort("Error: Advecting quantity is unrecognized");
        }
        break;
      case AdvectedQuantity::v:
        switch (advectingQuantity) {
          case AdvectingQuantity::rho_u:
            advectedVel = 1.0; // v(i-1/2,    j, k    )..Needs to be called properly
            advectingMom = 0.5*(rho_u(i+1, j, k) + rho_u(i+1, j-1, k));
            break;
          case AdvectingQuantity::rho_v:
            advectedVel = 1.0; // v(i   , j-1/2, k    )..Needs to be called properly
            advectingMom = 0.5*(rho_v(i, j+1, k) + rho_v(i, j, k));
            break;
          case AdvectingQuantity::rho_w:
            advectedVel = 1.0; // v(i   , j    , k-1/2)..Needs to be called properly
            advectingMom = 0.5*(rho_w(i, j, k+1) + rho_w(i, j-1, k+1));
            break;
          default:
            amrex::Abort("Error: Advecting quantity is unrecognized");
        }
        break;
      case AdvectedQuantity::w:
        switch (advectingQuantity) {
          case AdvectingQuantity::rho_u:
            advectedVel = 1.0; // w(i-1/2,    j, k    )..Needs to be called properly
            advectingMom = 0.5*(rho_u(i+1, j, k) + rho_u(i+1, j, k-1));
            break;
          case AdvectingQuantity::rho_v:
            advectedVel = 1.0; // w(i   , j-1/2, k    )..Needs to be called properly
            advectingMom = 0.5*(rho_v(i, j+1, k) + rho_v(i, j+1, k-1));
            break;
          case AdvectingQuantity::rho_w:
            advectedVel = 1.0; // w(i   , j    , k-1/2)..Needs to be called properly
            advectingMom = 0.5*(rho_w(i, j, k+1) + rho_w(i, j, k));
            break;
          default:
            amrex::Abort("Error: Advecting quantity is unrecognized");
        }
        break;
      default:
        amrex::Abort("Error: Advected quantity is unrecognized");
    }
  }

  return advectingMom*advectedVel;
}
